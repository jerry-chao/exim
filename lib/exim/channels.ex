defmodule Exim.Channels do
  alias Exim.{Repo, Channel, UserChannel}

  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  def get_channel!(id), do: Repo.get!(Channel, id)

  def list_channels do
    Repo.all(Channel)
  end

  def add_user_to_channel(user_id, channel_id) do
    %UserChannel{}
    |> UserChannel.changeset(%{user_id: user_id, channel_id: channel_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def list_channel_users(channel_id) do
    channel = Repo.get!(Channel, channel_id) |> Repo.preload(:users)
    channel.users
  end
end
