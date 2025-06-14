defmodule EximWeb.UserSocket do
  use Phoenix.Socket

  channel "*", EximWeb.RoomChannel

  require Logger

  def connect(%{"token" => token}, socket, _connect_info) do
    Logger.info("UserSocket connected #{inspect(socket)}, self pid #{inspect(self())}")

    case Phoenix.Token.verify(socket, "user token", token, max_age: 1_209_600) do
      {:ok, user_id} ->
        Logger.info("UserSocket connected user_id: #{user_id}")
        {:ok, assign(socket, :current_user, user_id)}

      {:error, reason} ->
        Logger.error("UserSocket connection failed: #{inspect(reason)}, token: #{inspect(token)}")
        :error
    end
  end

  def connect(params, socket) do
    Logger.info(
      "UserSocket connected without token: #{inspect(params)}, socket: #{inspect(socket)}"
    )

    :error
  end

  def id(_socket), do: nil
end
