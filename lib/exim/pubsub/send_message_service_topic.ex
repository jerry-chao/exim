defmodule Exim.PubSub.SendMessageServiceTopic do
  @moduledoc """
  This module show the example send message from websocket client.
  TODO websocket client is not implemented yet.
  """
  alias Phoenix.PubSub
  alias Ecto.UUID
  require Logger

  def generate(from, to) when from > to do
    from <> to
  end

  def generate(from, to) when from < to do
    to <> from
  end

  def send_message(from, to, message) do
    send_private_request = %{
      method: "private_message",
      params: %{
        from: from,
        to: to,
        message: message
      },
      key: generate(from, to),
      id: UUID.generate(),
      topic: "valid-msg-topic"
    }

    # sub the request id
    PubSub.subscribe(Exim.PubSub, send_private_request.id)
    request(send_private_request)
    # wait for send message success
    receive do
      response ->
        Logger.info("Received response: #{inspect(response)}")
        response
    end
  end

  def request(request) do
    topic = Map.get(request, :topic)
    client_id = topic |> String.to_atom()
    request = request |> Map.put(:jsonrpc, "2.0")
    Logger.info("Sending request to topic #{topic}")

    :brod.produce_sync(
      client_id,
      topic,
      :hash,
      Map.get(request, :key, ""),
      Jason.encode!(request)
    )

    request.id
  end
end
