defmodule Exim.Channels do
  import Ecto.Query, warn: false
  alias Exim.{Repo, Channel, UserChannel, User}

  @doc """
  Creates a channel with the given attributes.
  """
  def create_channel(attrs \\ %{}) do
    result =
      %Channel{}
      |> Channel.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, channel} ->
        # Add creator to the channel automatically
        if attrs[:creator_id] do
          add_user_to_channel(attrs[:creator_id], channel.id)
        end

        update_member_count(channel.id)
        {:ok, channel}

      error ->
        error
    end
  end

  @doc """
  Creates a public channel.
  """
  def create_public_channel(attrs) do
    attrs
    |> Map.put(:is_public, true)
    |> create_channel()
  end

  @doc """
  Creates a private channel.
  """
  def create_private_channel(attrs) do
    attrs
    |> Map.put(:is_public, false)
    |> create_channel()
  end

  @doc """
  Gets a channel by ID.
  """
  def get_channel!(id), do: Repo.get!(Channel, id)

  @doc """
  Gets a channel by ID with preloaded associations.
  """
  def get_channel_with_users!(id) do
    Repo.get!(Channel, id) |> Repo.preload(:users)
  end

  @doc """
  Lists all channels.
  """
  def list_channels do
    Repo.all(Channel)
  end

  @doc """
  Lists all public channels.
  """
  def list_public_channels do
    from(c in Channel, where: c.is_public == true, order_by: [desc: c.member_count, asc: c.name])
    |> Repo.all()
  end

  @doc """
  Searches public channels by name or description.
  """
  def search_public_channels(search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"

    from(c in Channel,
      where:
        c.is_public == true and
          (ilike(c.name, ^search_pattern) or ilike(c.description, ^search_pattern)),
      order_by: [desc: c.member_count, asc: c.name]
    )
    |> Repo.all()
  end

  def search_public_channels(_), do: list_public_channels()

  @doc """
  Lists channels that a user is a member of.
  """
  def list_user_channels(user_id) do
    from(c in Channel,
      join: uc in UserChannel,
      on: c.id == uc.channel_id,
      where: uc.user_id == ^user_id,
      order_by: c.name
    )
    |> Repo.all()
  end

  @doc """
  Lists public channels that a user is NOT a member of.
  """
  def list_available_channels_for_user(user_id) do
    user_channel_ids =
      from(uc in UserChannel,
        where: uc.user_id == ^user_id,
        select: uc.channel_id
      )
      |> Repo.all()

    from(c in Channel,
      where: c.is_public == true and c.id not in ^user_channel_ids,
      order_by: [desc: c.member_count, asc: c.name]
    )
    |> Repo.all()
  end

  @doc """
  Adds a user to a channel.
  """
  def add_user_to_channel(user_id, channel_id) do
    result =
      %UserChannel{}
      |> UserChannel.changeset(%{user_id: user_id, channel_id: channel_id})
      |> Repo.insert(on_conflict: :nothing)

    case result do
      {:ok, _user_channel} ->
        update_member_count(channel_id)
        {:ok, :joined}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Removes a user from a channel.
  """
  def remove_user_from_channel(user_id, channel_id) do
    case Repo.get_by(UserChannel, user_id: user_id, channel_id: channel_id) do
      nil ->
        {:error, :not_found}

      user_channel ->
        result = Repo.delete(user_channel)
        update_member_count(channel_id)
        result
    end
  end

  @doc """
  Checks if a user is a member of a channel.
  """
  def user_member_of_channel?(user_id, channel_id) do
    Repo.exists?(
      from uc in UserChannel,
        where: uc.user_id == ^user_id and uc.channel_id == ^channel_id
    )
  end

  @doc """
  Lists all users in a channel.
  """
  def list_channel_users(channel_id) do
    channel = Repo.get!(Channel, channel_id) |> Repo.preload(:users)
    channel.users
  end

  @doc """
  Updates the member count for a channel.
  """
  def update_member_count(channel_id) do
    count =
      from(uc in UserChannel, where: uc.channel_id == ^channel_id) |> Repo.aggregate(:count, :id)

    from(c in Channel, where: c.id == ^channel_id)
    |> Repo.update_all(set: [member_count: count])
  end

  @doc """
  Deletes a channel (only by creator or admin).
  """
  def delete_channel(channel_id, user_id) do
    channel = Repo.get!(Channel, channel_id)

    if channel.creator_id == user_id do
      Repo.delete(channel)
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Updates a channel (only by creator or admin).
  """
  def update_channel(channel_id, user_id, attrs) do
    channel = Repo.get!(Channel, channel_id)

    if channel.creator_id == user_id do
      channel
      |> Channel.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Gets channel statistics.
  """
  def get_channel_stats(channel_id) do
    channel = get_channel_with_users!(channel_id)

    %{
      id: channel.id,
      name: channel.name,
      description: channel.description,
      is_public: channel.is_public,
      member_count: channel.member_count,
      created_at: channel.inserted_at,
      creator_id: channel.creator_id
    }
  end
end
