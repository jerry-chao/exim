defmodule EximWeb.UserSessionController do
  use EximWeb, :controller

  alias Exim.Accounts
  alias EximWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
  end

  @doc """
  Handles token-based login from LiveView.
  Expects a token parameter and optional redirect_to parameter.
  """
  def token_login(conn, %{"token" => encoded_token} = params) do
    case Base.url_decode64(encoded_token) do
      {:ok, token} ->
        case Accounts.get_user_by_session_token(token) do
          %Exim.User{} = user ->
            redirect_to = Map.get(params, "redirect_to", "/")

            conn
            |> put_session(:user_token, token)
            |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
            |> assign(:current_user, user)
            |> redirect(to: redirect_to)

          nil ->
            conn
            |> put_flash(:error, "Invalid or expired login token")
            |> redirect(to: ~p"/login")
        end

      :error ->
        conn
        |> put_flash(:error, "Invalid login token format")
        |> redirect(to: ~p"/login")
    end
  end
end
