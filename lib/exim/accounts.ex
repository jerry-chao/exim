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
  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
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
end
