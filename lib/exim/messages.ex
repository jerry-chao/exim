defmodule Exim.Messages do
  import Ecto.Query
  alias Exim.Repo
  alias Exim.Message

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def list_messages do
    Message
    |> order_by(desc: :inserted_at)
    |> preload([:from])
    |> Repo.all()
  end

  def list_messages_by_channel(channel_id) do
    Message
    |> where([m], m.channel_id == ^channel_id)
    |> order_by(desc: :inserted_at)
    |> preload([:from])
    |> Repo.all()
  end

  def get_message!(id), do: Repo.get!(Message, id)

  def change_message(message \\ %Message{}, attrs) do
    Message.changeset(message, attrs)
  end
end
