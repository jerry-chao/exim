defmodule EximWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:" <> _room_id, _message, socket) do
    {:ok, socket}
  end

  def handle_in("new_message", %{"content" => body}, socket) do
    broadcast!(socket, "new_message", %{content: body})
    {:noreply, socket}
  end
end
