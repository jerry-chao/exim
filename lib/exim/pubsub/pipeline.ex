defmodule Exim.PubSub.Pipeline do
  use Broadway

  alias Broadway.Message
  alias Phoenix.PubSub
  require Logger

  def child_spec(opts) do
    queue_name = Keyword.fetch!(opts, :queue_name)
    pipeline_name = pipeline_name(queue_name)

    %{
      id: pipeline_name,
      start: {__MODULE__, :start_link, opts}
    }
  end

  def start_link(opts) do
    queue_name = Keyword.fetch!(opts, :queue_name)
    pipeline_name = pipeline_name(queue_name)

    pipeline_opts = [
      name: pipeline_name,
      producer: [
        module: {
          BroadwayKafka.Producer,
          [
            hosts: [localhost: 9092],
            group_id: "exim",
            topics: [queue_name]
          ]
        },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ]
    ]

    Logger.info("Starting pipeline for queue: #{queue_name}")

    case Broadway.start_link(__MODULE__, pipeline_opts) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  def pipeline_name(queue_name) do
    String.to_atom("pipeline_#{queue_name}")
  end

  @impl true
  def handle_message(_, message, _) do
    Logger.info("handle message, #{inspect(message)}")

    case handle_message_internal(Jason.decode!(message.data)) do
      :ok ->
        message

      {:error, reason} ->
        Message.failed(message, reason)
    end
  end

  # auth valid the auth request and give auth result to response topic
  # 1. valid the token
  # 2. send result to response topic
  defp handle_message_internal(%{"method" => "auth"} = message) do
    Logger.info("handle auth request, #{inspect(message)}")
    response = message |> Map.put("topic", "exim-auth") |> Map.put("method", "result")
    Exim.PubSub.Response.response(response)
  end

  # handle auth response
  # send result to request process
  defp handle_message_internal(%{"method" => "result", "id" => id} = message) do
    Logger.info("handle auth response, #{inspect(message)}")
    PubSub.broadcast(Exim.PubSub, id, message)
  end

  defp handle_message_internal(message) do
    Logger.info("handle unknown message: #{inspect(message)}")
    :ok
  end
end
