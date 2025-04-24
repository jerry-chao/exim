defmodule Exim.PubSub.Response do
  require Logger

  def response_topic(topic) do
    topic <> "-response"
  end

  def start_client(topic) do
    topic = response_topic(topic)
    client_id = topic |> String.to_atom()
    hosts = Application.get_env(:exim, :kafka_hosts)
    :ok = :brod.start_client(hosts, client_id, _client_config = [])
    :ok = :brod.start_producer(client_id, topic, _producer_config = [])
  end

  def response(response) do
    topic = Map.get(response, "topic", "") |> response_topic()
    client_id = topic |> String.to_atom()
    response = response |> Map.put("jsonrpc", "2.0")

    Logger.info(
      "Sending response to response #{inspect(response)}, topic: #{topic}, client_id: #{client_id}"
    )

    :brod.produce_sync(
      client_id,
      topic,
      :hash,
      Map.get(response, :key, ""),
      Jason.encode!(response)
    )
  end
end
