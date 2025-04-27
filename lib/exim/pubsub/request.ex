defmodule Exim.PubSub.Request do
  alias Ecto.UUID
  alias Phoenix.PubSub

  require Logger

  def start_client(topic) do
    client_id = topic |> String.to_atom()
    hosts = Application.get_env(:exim, :kafka_hosts)
    :ok = :brod.start_client(hosts, client_id, _client_config = [])
    :ok = :brod.start_producer(client_id, topic, _producer_config = [])
  end

  def auth(uid, token) do
    auth_request = %{
      method: "auth",
      params: %{
        uid: uid,
        token: token
      },
      key: uid,
      id: UUID.generate()
    }

    # sub the request id
    PubSub.subscribe(Exim.PubSub, auth_request.id)
    request(auth_request)
    # wait for response
    receive do
      response ->
        Logger.info("Received response: #{inspect(response)}")
        response
    end
  end

  def request(request) do
    topic = "exim-" <> Map.get(request, :method)
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
