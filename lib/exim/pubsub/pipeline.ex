defmodule Exim.PubSub.Pipeline do
  use Broadway

  alias Broadway.Message
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
            topics: ["exim-auth"]
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

    case publish_to_pubsub(Jason.decode!(message.data)) do
      :ok ->
        message

      {:error, reason} ->
        Message.failed(message, reason)
    end
  end

  defp publish_to_pubsub(%{"method" => "auth"} = message) do
    response = message |> Map.put("topic", "exim-auth") |> Map.put("method", "result")
    Exim.PubSub.Response.response(response)
  end

  defp publish_to_pubsub(message) do
    Logger.info("handle unknown message: #{inspect(message)}")
    :ok
  end
end
