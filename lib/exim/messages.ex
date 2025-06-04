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
    |> preload(:user)
    |> Repo.all()
  end

  def get_message!(id), do: Repo.get!(Message, id)
end
