defmodule EximWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", EximWeb.RoomChannel

  require Logger

  def connect(_params, socket) do
    Logger.info("UserSocket connected ...")
    {:ok, socket}
  end

  def id(_socket), do: nil
end
