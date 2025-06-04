defmodule EximWeb.ChatLive do
  use EximWeb, :live_view
  alias Exim.Messages
  alias Exim.Message

  def mount(_params, _session, socket) do
    if connected?(socket) do
      EximWeb.Endpoint.subscribe("chat")
    end

    {:ok,
     assign(socket,
       messages: Messages.list_messages(),
       form: to_form(%{}, as: "message")
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto">
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h1 class="text-2xl font-bold mb-4">Chat Room</h1>

          <div id="messages" phx-update="append" class="space-y-4 mb-4 h-[500px] overflow-y-auto">
            <%= for message <- @messages do %>
              <div id={"message-#{message.id}"} class="flex items-start space-x-2">
                <div class="flex-1">
                  <div class="bg-gray-100 rounded-lg p-3">
                    <p class="font-semibold text-sm text-gray-600">{message.user.username}</p>
                    <p class="text-gray-800">{message.content}</p>
                    <p class="text-xs text-gray-500 mt-1">
                      {Calendar.strftime(message.inserted_at, "%Y-%m-%d %H:%M:%S")}
                    </p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <.simple_form for={@form} id="message-form" phx-submit="send_message">
            <div class="flex space-x-2">
              <.input
                field={@form[:content]}
                type="text"
                placeholder="Type your message..."
                class="flex-1"
              />
              <.button type="submit" phx-disable-with="Sending...">Send</.button>
            </div>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    case Messages.create_message(%{content: content, user_id: socket.assigns.current_user.id}) do
      {:ok, message} ->
        EximWeb.Endpoint.broadcast("chat", "new_message", message)
        {:noreply, assign(socket, form: to_form(%{}, as: "message"))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to send message")
         |> assign(form: to_form(%{}, as: "message"))}
    end
  end

  def handle_info(%{event: "new_message", payload: message}, socket) do
    {:noreply, stream_insert(socket, :messages, message, at: -1)}
  end
end
