defmodule EximWeb.ChatLive do
  use EximWeb, :live_view
  alias Exim.{Messages, Accounts, Channels}
  require Logger

  def mount(params, session, socket) do
    user =
      cond do
        Map.has_key?(socket.assigns, :current_user) && socket.assigns.current_user ->
          socket.assigns.current_user

        session["user_token"] ->
          Accounts.get_user_by_session_token(session["user_token"])

        true ->
          nil
      end

    Logger.info("User: #{inspect(user)}")

    if is_nil(user) do
      {:ok, redirect(socket, to: "/login")}
    else
      channels = Channels.list_user_channels(user.id)

      # Check for channel parameter in URL
      current_channel =
        case params do
          %{"channel" => channel_id_str} ->
            case Integer.parse(channel_id_str) do
              {channel_id, _} ->
                # Verify user is member of this channel
                if Channels.user_member_of_channel?(user.id, channel_id) do
                  Channels.get_channel!(channel_id)
                else
                  List.first(channels)
                end

              _ ->
                List.first(channels)
            end

          _ ->
            List.first(channels)
        end

      messages =
        if current_channel, do: Messages.list_messages_by_channel(current_channel.id), else: []

      # Subscribe to current channel if connected
      if connected?(socket) && current_channel do
        EximWeb.Endpoint.subscribe("channel:#{current_channel.id}")
      end

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
    {channel_id, _} = Integer.parse(id)

    # Verify user is member of this channel
    if Channels.user_member_of_channel?(socket.assigns.current_user.id, channel_id) do
      # Unsubscribe from previous channel
      if socket.assigns.current_channel do
        EximWeb.Endpoint.unsubscribe("channel:#{socket.assigns.current_channel.id}")
      end

      # Get new channel and subscribe
      channel = Channels.get_channel!(channel_id)
      messages = Messages.list_messages_by_channel(channel.id)

      if connected?(socket) do
        EximWeb.Endpoint.subscribe("channel:#{channel.id}")
      end

      {:noreply, assign(socket, current_channel: channel, messages: messages)}
    else
      {:noreply, put_flash(socket, :error, "You are not a member of this channel")}
    end
  end

  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    user = socket.assigns.current_user
    channel = socket.assigns.current_channel

    if user && channel && String.trim(content) != "" do
      # Verify user is still a member of the channel
      if Channels.user_member_of_channel?(user.id, channel.id) do
        {:ok, message} =
          Messages.create_message(%{
            content: String.trim(content),
            from_id: user.id,
            channel_id: channel.id
          })

        # Preload the from association before broadcasting
        message_with_from = Exim.Repo.preload(message, :from)
        EximWeb.Endpoint.broadcast("channel:#{channel.id}", "new_message", message_with_from)

        {:noreply, assign(socket, form: to_form(%{}, as: "message"))}
      else
        {:noreply,
         socket
         |> put_flash(:error, "You are no longer a member of this channel")
         |> redirect(to: ~p"/channels")}
      end
    else
      {:noreply, assign(socket, form: to_form(%{}, as: "message"))}
    end
  end

  def handle_info(%{event: "new_message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end
end
