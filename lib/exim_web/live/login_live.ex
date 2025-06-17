defmodule EximWeb.LoginLive do
  use EximWeb, :live_view
  alias Exim.Accounts

  def mount(_params, session, socket) do
    # Check if user is already logged in
    current_user = if session["user_token"] do
      Accounts.get_user_by_session_token(session["user_token"])
    else
      nil
    end
    
    if current_user do
      {:ok, redirect(socket, to: ~p"/chat")}
    else
      {:ok, assign(socket, form: to_form(%{}, as: "user"), current_user: nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Sign in to your account
        <:actions>
          <.link patch={~p"/register"} class="font-semibold text-brand hover:underline">
            Register
          </.link>
        </:actions>
      </.header>

      <.simple_form for={@form} id="login-form" phx-submit="login">
        <.error :if={@form.errors != []}>
          Oops, something went wrong! Please check the form below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in
          </.button>
        </:actions>
      </.simple_form>
      
      <div class="text-center mt-4">
        <.link href={~p"/users/sessions"} method="delete" class="text-sm text-gray-600 hover:text-brand">
          Sign out (if already logged in)
        </.link>
      </div>
    </div>
    """
  end

  def handle_event("login", %{"user" => %{"email" => email, "password" => password}}, socket) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Generate session token for the user
        token = Accounts.generate_user_session_token(user)
        
        # Subscribe to user's personal channel
        if connected?(socket) do
          EximWeb.Endpoint.subscribe("user:#{user.id}")
        end

        # In LiveView, we need to redirect to a controller action that will set the session
        # We'll pass the token as a parameter to be handled by the controller
        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> redirect(external: "/users/sessions?token=#{Base.url_encode64(token)}&redirect_to=#{URI.encode("/chat")}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(form: to_form(%{}, as: "user"))}
    end
  end
end
