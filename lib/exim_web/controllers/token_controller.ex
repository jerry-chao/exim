defmodule EximWeb.TokenController do
  @moduledoc """
  Controller for generating authentication tokens.
  Provides endpoints for token generation via:
  1. Direct username/password authentication
  2. Existing session authentication
  """
  use EximWeb, :controller
  import Plug.Conn
  alias Exim.Accounts

  @doc """
  Generates a token when provided with valid email and password credentials.
  Accepts: POST request with {"user": {"email": "user@example.com", "password": "password"}}
  Returns: {"token": "generated_token"} or 401 error
  """
  def get_token(conn, %{"user" => %{"email" => email, "password" => password}}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Phoenix.Token.sign(conn, "user token", user.id)
      json(conn, %{token: token})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Invalid email or password"})
    end
  end
end
