defmodule EximWeb.TokenController do
  @moduledoc """
  Controller for generating and managing authentication tokens.
  Provides endpoints for:
  1. Token generation via email/password authentication
  2. Token verification
  3. Token invalidation (logout)
  """
  use EximWeb, :controller
  import Plug.Conn
  alias Exim.Accounts

  @doc """
  Generates a session token when provided with valid email and password credentials.
  Accepts: POST request with {"user": {"email": "user@example.com", "password": "password"}}
  Returns: {"token": "generated_session_token", "user": user_data} or 401 error
  """
  def get_token(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Generate session token using the same system as web login
        token = Accounts.generate_user_session_token(user)
        
        json(conn, %{
          token: Base.url_encode64(token),
          user: %{
            id: user.id,
            email: user.email,
            username: user.username
          }
        })
        
      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  @doc """
  Verifies a session token and returns user information.
  Accepts: GET request with Authorization header: "Bearer <token>"
  Returns: {"user": user_data} or 401 error
  """
  def verify_token(conn, _params) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Base.url_decode64(token) do
          {:ok, decoded_token} ->
            case Accounts.get_user_by_session_token(decoded_token) do
              %Exim.User{} = user ->
                json(conn, %{
                  user: %{
                    id: user.id,
                    email: user.email,
                    username: user.username
                  }
                })
              
              nil ->
                conn
                |> put_status(:unauthorized)
                |> json(%{error: "Invalid or expired token"})
            end
            
          :error ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token format"})
        end
        
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authorization header missing or invalid"})
    end
  end

  @doc """
  Invalidates a session token (logout).
  Accepts: DELETE request with Authorization header: "Bearer <token>"
  Returns: {"message": "Token invalidated"} or 401 error
  """
  def invalidate_token(conn, _params) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Base.url_decode64(token) do
          {:ok, decoded_token} ->
            Accounts.delete_user_session_token(decoded_token)
            json(conn, %{message: "Token invalidated successfully"})
            
          :error ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token format"})
        end
        
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authorization header missing or invalid"})
    end
  end
end
