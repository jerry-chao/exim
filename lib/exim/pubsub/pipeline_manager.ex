defmodule Exim.PubSub.PipelineManager do
  use GenServer

  @timeout :timer.minutes(1)
  require Logger

  def add_queue(queue_name) do
    GenServer.call(__MODULE__, {:add_queue, queue_name})
  end

  def remove_queue(queue_name) do
    GenServer.call(__MODULE__, {:remove_queue, queue_name})
  end

  def get_queues do
    GenServer.call(__MODULE__, :get_queues)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    state = %{managed_queues: MapSet.new()}

    {:ok, state, {:continue, :start}}
  end

  def handle_continue(:start, state) do
    state = manage_queues(state, MapSet.new(), MapSet.new())

    {:noreply, state, @timeout}
  end

  def handle_call({:add_queue, queue_name}, _from, state) do
    state = manage_queues(state, MapSet.new([queue_name]), MapSet.new())

    {:reply, :ok, state}
  end

  def handle_call({:remove_queue, queue_name}, _from, state) do
    state = manage_queues(state, MapSet.new(), MapSet.new([queue_name]))

    {:reply, :ok, state}
  end

  def handle_call({:get_queues}, _from, state) do
    {:reply, state.managed_queues, state}
  end

  def handle_info(:timeout, state) do
    {:noreply, state, @timeout}
  end

  def manage_queues(state, queues_to_add, queues_to_remove) do
    Enum.each(queues_to_add, &start_pipeline/1)
    Enum.each(queues_to_remove, &stop_pipeline/1)

    new_queues = MapSet.union(state.managed_queues, queues_to_add)
    new_queues = MapSet.difference(new_queues, queues_to_remove)

    %{state | managed_queues: new_queues}
  end

  defp start_pipeline(queue_name) do
    Logger.info("Starting pipeline for queue: #{queue_name}")
    pipeline_name = Exim.PubSub.Pipeline.pipeline_name(queue_name)

    case Horde.Registry.lookup(Exim.PubSub.Pipeline.PipelineRegistry, pipeline_name) do
      [{_pid, _}] ->
        {:error, :already_started}

      [] ->
        opts = [queue_name: queue_name]

        Logger.info("Pipeline started for queue: #{queue_name}, opts: #{inspect(opts)}")

        result =
          Horde.DynamicSupervisor.start_child(
            Exim.PubSub.Pipeline.PipelineSupervisor,
            %{id: pipeline_name, start: {Exim.PubSub.Pipeline, :start_link, [opts]}}
          )

        Logger.info(
          "Pipeline started for queue: #{queue_name}, result: #{inspect(result)}, opts: #{inspect(opts)}"
        )

        result
    end
  end

  defp stop_pipeline(queue_name) do
    pipeline_name = Exim.PubSub.Pipeline.pipeline_name(queue_name)

    case Horde.Registry.lookup(Exim.PubSub.Pipeline.PipelineRegistry, pipeline_name) do
      [{pid, _}] ->
        Horde.DynamicSupervisor.terminate_child(Exim.PubSub.Pipeline.PipelineSupervisor, pid)

      [] ->
        {:error, :not_found}
    end
  end
end
