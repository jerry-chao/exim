defmodule EximWeb.LoginLive do
  use EximWeb, :live_view
  alias Exim.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
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
    </div>
    """
  end

  def handle_event("login", %{"user" => %{"email" => email, "password" => password}}, socket) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Subscribe to user's personal channel
        if connected?(socket) do
          EximWeb.Endpoint.subscribe("user:#{user.id}")
        end

        {:noreply,
         socket
         |> put_flash(:info, "Welcome back!")
         |> redirect(to: ~p"/chat")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(form: to_form(%{}, as: "user"))}
    end
  end
end
