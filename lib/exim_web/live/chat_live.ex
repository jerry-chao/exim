defmodule EximWeb.ChatLive do
  use EximWeb, :live_view
  alias Exim.{Messages, Accounts, Channels}

  def mount(_params, session, socket) do
    user =
      cond do
        Map.has_key?(socket.assigns, :current_user) && socket.assigns.current_user ->
          socket.assigns.current_user

        session["user_token"] ->
          Accounts.get_user_by_session_token(session["user_token"])

        true ->
          nil
      end

    if is_nil(user) do
      {:ok, redirect(socket, to: "/login")}
    else
      channels = Accounts.get_user_channels(user.id)
      current_channel = List.first(channels)

      messages =
        if current_channel, do: Messages.list_messages_by_channel(current_channel.id), else: []

      {:ok,
       assign(socket,
         current_user: user,
         channels: channels,
         current_channel: current_channel,
         messages: messages,
         form: to_form(%{}, as: "message")
       )}
    end
  end

  def handle_event("select_channel", %{"id" => id}, socket) do
    channel = Enum.find(socket.assigns.channels, &("#{&1.id}" == id))
    messages = Messages.list_messages_by_channel(channel.id)
    {:noreply, assign(socket, current_channel: channel, messages: messages)}
  end

  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    user = socket.assigns.current_user
    channel = socket.assigns.current_channel

    if user && channel do
      {:ok, message} =
        Messages.create_message(%{
          content: content,
          from_id: user.id,
          # 可扩展为@提及或私聊
          to_id: nil,
          channel_id: channel.id
        })

      EximWeb.Endpoint.broadcast("channel:#{channel.id}", "new_message", message)
    end

    {:noreply, assign(socket, form: to_form(%{}, as: "message"))}
  end

  def handle_info(%{event: "new_message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end
end
