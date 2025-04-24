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
            group_id: "group_1",
            topics: ["test"]
          ]
        },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ],
      batchers: [
        default: [
          batch_size: 100,
          batch_timeout: 200,
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
    message
    |> Message.update_data(&process_data/1)
  end

  @impl true
  def handle_batch(_, messages, _, _) do
    case publish_to_pubsub(messages) do
      :ok ->
        messages

      {:error, reason} ->
        # Mark messages as failed
        Enum.map(messages, &Message.failed(&1, reason))
    end
  end

  defp process_data(data) do
    # Transform message data as needed
    data
  end

  defp publish_to_pubsub(messages) do
    Logger.info(
      "Publishing messages to PubSub, #{length(messages)} messages, #{inspect(messages)}"
    )
  end
end
