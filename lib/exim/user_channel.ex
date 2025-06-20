defmodule Exim.UserChannel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_channels" do
    belongs_to :user, Exim.Accounts.User
    belongs_to :channel, Exim.Channel
    timestamps()
  end

  def changeset(user_channel, attrs) do
    user_channel
    |> cast(attrs, [:user_id, :channel_id])
    |> validate_required([:user_id, :channel_id])
    |> unique_constraint([:user_id, :channel_id])
  end
end
