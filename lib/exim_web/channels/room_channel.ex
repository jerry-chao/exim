defmodule EximWeb.RoomChannel do
  use Phoenix.Channel
  require Logger

  def join(_room_id, _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_message", %{"content" => body}, socket) do
    Logger.info("Received new message: #{inspect(body)}, socket: #{inspect(socket)}")
    broadcast!(socket, "new_message", %{message: body, topic: socket.topic})
    {:reply, :ok, socket}
  end
end
