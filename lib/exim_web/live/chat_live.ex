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

  def render(assigns) do
    ~H"""
    <div class="h-full flex">
      <!-- Conversations Sidebar -->
      <div class="w-64 bg-gray-100 border-r border-gray-200">
        <div class="p-4">
          <h2 class="text-lg font-semibold text-gray-700">Conversations</h2>
        </div>
        <div class="overflow-y-auto h-[calc(100vh-4rem)]">
          <%= for conv <- @conversations do %>
            <div
              class={"p-4 cursor-pointer hover:bg-gray-200 #{if conv.id == @current_conversation, do: "bg-gray-200"}"}
              phx-click="select_conversation"
              phx-value-id={conv.id}
            >
              <div class="flex justify-between items-center">
                <span class="font-medium">{conv.name}</span>
                <%= if conv.unread > 0 do %>
                  <span class="bg-blue-500 text-white text-xs px-2 py-1 rounded-full">
                    {conv.unread}
                  </span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Chat Area -->
      <div class="flex-1 flex flex-col">
        <!-- Chat Header -->
        <div class="border-b p-4 bg-white">
          <h1 class="text-xl font-semibold">
            {Enum.find(@conversations, &(&1.id == @current_conversation)).name}
          </h1>
        </div>
        
    <!-- Messages -->
        <div class="flex-1 overflow-y-auto p-6 space-y-4 bg-gray-50" id="messages">
          <%= for message <- @messages do %>
            <div id={"message-#{message.id}"} class="flex items-start space-x-2">
              <div class="flex-1">
                <div class="bg-white rounded-lg p-4 shadow-sm">
                  <p class="font-semibold text-sm text-gray-600">{message.user.username}</p>
                  <p class="text-gray-800 text-lg">{message.content}</p>
                  <p class="text-xs text-gray-500 mt-1">
                    {Calendar.strftime(message.inserted_at, "%Y-%m-%d %H:%M:%S")}
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Message Input -->
        <div class="border-t bg-white p-6">
          <.simple_form
            for={@form}
            id="message-form"
            phx-submit="send_message"
            class="w-full max-w-[90%] mx-auto"
          >
            <div class="flex items-center gap-4">
              <.input
                field={@form[:content]}
                type="text"
                placeholder="Type your message..."
                class="flex-1 rounded-xl border-gray-300 focus:border-blue-500 focus:ring-blue-500 text-lg py-4 px-4"
              />
              <.button
                type="submit"
                phx-disable-with="Sending..."
                class="px-8 py-4 bg-blue-600 text-white font-medium text-lg rounded-xl hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors min-w-[120px]"
              >
                Send
              </.button>
            </div>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("select_conversation", %{"id" => id}, socket) do
    {:noreply, assign(socket, current_conversation: String.to_integer(id))}
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
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end
end
