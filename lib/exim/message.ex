defmodule Exim.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias Exim.User
  alias Exim.Channel

  schema "messages" do
    field :content, :string
    belongs_to :from, User, foreign_key: :from_id
    belongs_to :to, User, foreign_key: :to_id
    belongs_to :channel, Channel

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :from_id, :to_id, :channel_id])
    |> validate_required([:content, :from_id, :to_id, :channel_id])
    |> validate_length(:content, min: 1)
    |> foreign_key_constraint(:from_id)
    |> foreign_key_constraint(:to_id)
    |> foreign_key_constraint(:channel_id)
  end
end
