defmodule Exim.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Exim.Repo
  alias Exim.User

  # UserToken schema for session handling
  defmodule UserToken do
    use Ecto.Schema
    import Ecto.Query

    @hash_algorithm :sha256
    @rand_size 32

    # It is very important to keep the reset password token expiry short,
    # since someone with access to the email may take over the account.
    @reset_password_validity_in_days 1
    @confirm_validity_in_days 7
    @session_validity_in_days 60

    schema "users_tokens" do
      field :token, :binary
      field :context, :string
      belongs_to :user, User

      timestamps(updated_at: false)
    end

    @doc """
    Generates a token that will be stored in a signed place,
    such as session or cookie. As they are signed, those
    tokens do not need to be hashed.

    The reason why we store session tokens in the database, even
    though Phoenix already provides a session cookie, is because
    Phoenix' default session cookies are not persisted, they are
    simply signed and potentially encrypted. This means they are
    valid indefinitely, unless you change the signing/encryption
    salt.

    Therefore, we store a token in the database to ensure that even
    if the salt changes, we can still validate the token in the
    database.
    """
    def build_session_token(user) do
      token = :crypto.strong_rand_bytes(@rand_size)
      {token, %UserToken{token: token, context: "session", user_id: user.id}}
    end

    @doc """
    Checks if the token is valid and returns its underlying lookup query.

    The query returns the user found by the token, if any.
    """
    def verify_session_token_query(token) do
      query =
        from token in token_and_context_query(token, "session"),
          join: user in assoc(token, :user),
          where: token.inserted_at > ago(@session_validity_in_days, "day"),
          select: user

      {:ok, query}
    end

    @doc """
    Builds a token with a hashed counter used for user confirmation.
    """
    def build_email_token(user, context) do
      build_hashed_token(user, context, user.email)
    end

    defp build_hashed_token(user, context, _sent_to) do
      token = :crypto.strong_rand_bytes(@rand_size)
      hashed_token = :crypto.hash(@hash_algorithm, token)

      {Base.url_encode64(token, padding: false),
       %UserToken{
         token: hashed_token,
         context: context,
         user_id: user.id
       }}
    end

    @doc """
    Verifies the token for user confirmation and reset password.
    """
    def verify_email_token_query(token, context) do
      case Base.url_decode64(token, padding: false) do
        {:ok, decoded_token} ->
          hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
          days = days_for_context(context)

          query =
            from token in token_and_context_query(hashed_token, context),
              join: user in assoc(token, :user),
              where: token.inserted_at > ago(^days, "day"),
              select: user

          {:ok, query}

        :error ->
          :error
      end
    end

    defp days_for_context("confirm"), do: @confirm_validity_in_days
    defp days_for_context("reset_password"), do: @reset_password_validity_in_days

    @doc """
    Returns the token struct for the given token value and context.
    """
    def token_and_context_query(token, context) do
      from UserToken, where: [token: ^token, context: ^context]
    end

    @doc """
    Gets all tokens for the given user.
    """
    def user_and_contexts_query(user, contexts) do
      from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
    end
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a user by email and password.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    if user && User.valid_password?(user, password) do
      user
    end
  end

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Updates the user's password.

  ## Examples

      iex> update_user_password(user, "current password", %{password: "new password"})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid", %{password: "new password"})
      {:error, %Ecto.Changeset{}}
  """
  def update_user_password(user, current_password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)

    with {:ok, _} <- User.validate_current_password(user, current_password) do
      Ecto.Multi.new()
      |> Ecto.Multi.update(:user, changeset)
      |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["session"]))
      |> Repo.transaction()
      |> case do
        {:ok, %{user: user}} -> {:ok, user}
        {:error, :user, changeset, _} -> {:error, changeset}
      end
    end
  end

  @doc """
  Confirms a user by token.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  @doc """
  Resets the user password using a token.
  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["reset_password"]))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Gets the user by reset password token.
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Delivers instructions to reset a user password.
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_url_fun) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    %{to: user.email, url: reset_url_fun.(encoded_token), user: user}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Returns a changeset for changing the user's email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(%User{} = user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Applies changes to the user's email.

  ## Examples

      iex> apply_user_email(user, %{email: "new@example.com"})
      %Ecto.Changeset{data: %User{}}

  """
  def apply_user_email(%User{} = user, user_params) do
    User.email_changeset(user, user_params) |> Repo.update()
  end

  @doc """
  Returns a changeset for changing the user's password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end

  @doc """
  Authenticates a user by email and password.

  ## Examples

      iex> authenticate_user("foo@example.com", "correct_password")
      {:ok, %User{}}

      iex> authenticate_user("foo@example.com", "invalid_password")
      {:error, :unauthorized}

      iex> authenticate_user("unknown@example.com", "password")
      {:error, :not_found}

  """
  def authenticate_user(email, password) do
    user = Repo.get_by(User, email: email)

    cond do
      user && User.valid_password?(user, password) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end

  def get_user_channels(user_id) do
    user = Repo.get!(User, user_id) |> Repo.preload(:channels)
    user.channels
  end
end
