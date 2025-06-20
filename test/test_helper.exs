ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Exim.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:exim)
