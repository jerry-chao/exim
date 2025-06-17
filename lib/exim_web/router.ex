defmodule EximWeb.Router do
  use EximWeb, :router

  import EximWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EximWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_user_token
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user token", current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_user
  end

  scope "/", EximWeb do
    pipe_through :browser
    live "/", LoginLive, :index
    live "/register", RegistrationLive, :new
    live "/login", LoginLive, :new
    live "/chat", ChatLive, :index
    
    # Session management routes
    get "/users/sessions", UserSessionController, :token_login
    delete "/users/sessions", UserSessionController, :delete
    delete "/users/log_out", UserSessionController, :delete
  end

  # API routes for token management
  scope "/api", EximWeb do
    pipe_through :api
    
    post "/auth/login", TokenController, :get_token
    get "/auth/verify", TokenController, :verify_token
    delete "/auth/logout", TokenController, :invalidate_token
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:exim, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EximWeb.Telemetry
    end
  end
end
