defmodule Exim.Repo do
  use Ecto.Repo,
    otp_app: :exim,
    adapter: Ecto.Adapters.Postgres
end
