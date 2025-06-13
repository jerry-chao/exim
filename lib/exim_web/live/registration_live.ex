defmodule EximWeb.RegistrationLive do
  use EximWeb, :live_view
  alias Exim.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register Account
        <:subtitle>Already registered?</:subtitle>
        <:actions>
          <.link patch={~p"/login"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
        </:actions>
      </.header>

      <.simple_form for={@form} id="registration-form" phx-submit="save" phx-change="validate">
        <.error :if={@form.errors != []}>
          Oops, something went wrong! Please check the form below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:username]} type="text" label="Username" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">
            Create an account
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    form = to_form(user_params, as: "user")
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully!")
         |> redirect(to: ~p"/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
    end
  end
end
