defmodule Exim.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Exim.Message

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :confirmed_at, :utc_datetime
    has_many :sent_messages, Message, foreign_key: :from_id
    has_many :received_messages, Message, foreign_key: :to_id
    many_to_many :channels, Exim.Channel, join_through: "user_channels"

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_required([:email, :username, :password])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash()
    |> put_change(:confirmed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> changeset(attrs)
    |> validate_email(opts)
  end

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> validate_email(opts)
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> maybe_hash_password(opts)
  end

  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  defp validate_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    else
      changeset
    end
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  defp maybe_hash_password(changeset, opts) do
    if Keyword.get(opts, :hash_password, true) do
      put_password_hash(changeset)
    else
      changeset
    end
  end

  def valid_password?(%__MODULE__{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, password_hash)
  end

  def valid_password?(_, _), do: Bcrypt.no_user_verify()

  def validate_current_password(user, password) do
    if valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :unauthorized}
    end
  end
end
