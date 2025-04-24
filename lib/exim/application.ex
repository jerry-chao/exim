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
      {Cluster.Supervisor, [topologies, [name: Exim.ClusterSupervisor]]},
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
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EximWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
