defmodule EximWeb.ChatLive do
  use EximWeb, :live_view
  alias Exim.Messages

  def mount(_params, _session, socket) do
    if connected?(socket) do
      EximWeb.Endpoint.subscribe("chat")
    end

    {:ok,
     assign(socket,
       messages: Messages.list_messages(),
       conversations: [
         %{id: 1, name: "General Chat", unread: 0},
         %{id: 2, name: "Support", unread: 3},
         %{id: 3, name: "Team", unread: 1}
       ],
       current_conversation: 1,
       form: to_form(%{}, as: "message")
     )}
  end

  def handle_event("select_conversation", %{"id" => id}, socket) do
    {:noreply, assign(socket, current_conversation: String.to_integer(id))}
  end

  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    if user = socket.assigns.current_user do
      EximWeb.Endpoint.broadcast("user:#{user.id}", "new_message", %{
        content: content,
        user_id: user.id
      })
    end

    {:noreply, assign(socket, form: to_form(%{}, as: "message"))}
  end

  def handle_info(%{event: "new_message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end
end
