defmodule Exim.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :name, :string
    field :description, :string
    field :is_public, :boolean, default: true
    field :creator_id, :id
    field :member_count, :integer, default: 0
    belongs_to :creator, Exim.User, foreign_key: :creator_id, define_field: false
    many_to_many :users, Exim.User, join_through: "user_channels"
    timestamps()
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:name, :description, :is_public, :creator_id])
    |> validate_required([:name, :creator_id])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:name)
    |> validate_format(:name, ~r/^[a-zA-Z0-9\-_\s]+$/,
      message: "can only contain letters, numbers, hyphens, underscores, and spaces"
    )
  end

  def public_changeset(channel, attrs) do
    changeset(channel, Map.put(attrs, :is_public, true))
  end

  def private_changeset(channel, attrs) do
    changeset(channel, Map.put(attrs, :is_public, false))
  end
end
