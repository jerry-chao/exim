defmodule Exim.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:"exim@127.0.0.1"]]
      ]
    ]

    children = [
      {Horde.Registry,
       [
         name: Exim.PubSub.Pipeline.PipelineRegistry,
         members: :auto,
         keys: :unique
       ]},
      {Horde.DynamicSupervisor,
       [
         name: Exim.PubSub.Pipeline.PipelineSupervisor,
         members: :auto,
         strategy: :one_for_one,
         distribution_strategy: Horde.UniformQuorumDistribution
       ]},
      {Cluster.Supervisor, [topologies, [name: Exim.ClusterSupervisor]]},
      {Exim.PubSub.PipelineManager, []},
      EximWeb.Telemetry,
      Exim.Repo,
      {Phoenix.PubSub, name: Exim.PubSub},
      # Start a worker by calling: Exim.Worker.start_link(arg)
      # {Exim.Worker, arg},
      # Start to serve requests, typically the last entry
      EximWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exim.Supervisor]
    appSupervisor = Supervisor.start_link(children, opts)
    start_request()
    start_broadway()
    appSupervisor
  end

  def start_request() do
    Enum.each(Application.get_env(:exim, :kafka_topics, []), fn topic ->
      Exim.PubSub.Request.start_client(topic)
    end)
  end

  def start_broadway() do
    Enum.each(Application.get_env(:exim, :kafka_topics, []), fn topic ->
      Exim.PubSub.PipelineManager.add_queue(topic)
      Exim.PubSub.Response.start_client(topic)
    end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EximWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
