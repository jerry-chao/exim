defmodule Exim.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias Exim.User

  schema "messages" do
    field :content, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id])
    |> validate_required([:content, :user_id])
    |> validate_length(:content, min: 1)
    |> foreign_key_constraint(:user_id)
  end
end
