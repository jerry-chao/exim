defmodule EximWeb.ChannelManagerLive do
  use EximWeb, :live_view
  alias Exim.{Channels, Accounts}

  def mount(_params, session, socket) do
    user =
      if session["user_token"] do
        Accounts.get_user_by_session_token(session["user_token"])
      else
        nil
      end

    if is_nil(user) do
      {:ok, redirect(socket, to: "/login")}
    else
      user_channels = Channels.list_user_channels(user.id)
      available_channels = Channels.list_available_channels_for_user(user.id)

      {:ok,
       assign(socket,
         current_user: user,
         user_channels: user_channels,
         available_channels: available_channels,
         search_results: [],
         search_term: "",
         show_create_form: false,
         show_search: false,
         create_form: to_form(%{}, as: "channel"),
         search_form: to_form(%{}, as: "search")
       )}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto p-6">
      <.header class="mb-8">
        Channel Manager
        <:subtitle>Create channels, discover public channels, and manage your memberships</:subtitle>
        <:actions>
          <.button phx-click="toggle_create_form" class="bg-blue-600 hover:bg-blue-700">
            <.icon name="hero-plus" class="h-4 w-4 mr-2" /> Create Channel
          </.button>
          <.button phx-click="toggle_search" class="bg-green-600 hover:bg-green-700">
            <.icon name="hero-magnifying-glass" class="h-4 w-4 mr-2" /> Search Channels
          </.button>
        </:actions>
      </.header>
      
    <!-- Create Channel Form -->
      <div :if={@show_create_form} class="mb-8 p-6 bg-blue-50 rounded-lg border border-blue-200">
        <h3 class="text-lg font-semibold text-blue-900 mb-4">Create New Channel</h3>
        <.simple_form for={@create_form} phx-submit="create_channel" class="space-y-4">
          <.input
            field={@create_form[:name]}
            label="Channel Name"
            placeholder="e.g., general, random, tech-talk"
            required
          />
          <.input
            field={@create_form[:description]}
            type="textarea"
            label="Description"
            placeholder="What is this channel about?"
          />
          <.input
            field={@create_form[:is_public]}
            type="checkbox"
            label="Make this channel public"
            checked
          />
          <:actions>
            <.button type="submit" class="bg-blue-600 hover:bg-blue-700">Create Channel</.button>
            <.button
              type="button"
              phx-click="toggle_create_form"
              class="bg-gray-500 hover:bg-gray-600"
            >
              Cancel
            </.button>
          </:actions>
        </.simple_form>
      </div>
      
    <!-- Search Channels -->
      <div :if={@show_search} class="mb-8 p-6 bg-green-50 rounded-lg border border-green-200">
        <h3 class="text-lg font-semibold text-green-900 mb-4">Search Public Channels</h3>
        <.simple_form
          for={@search_form}
          phx-submit="search_channels"
          phx-change="search_channels"
          class="space-y-4"
        >
          <.input
            field={@search_form[:term]}
            label="Search Term"
            placeholder="Search by name or description..."
            value={@search_term}
          />
          <:actions>
            <.button type="submit" class="bg-green-600 hover:bg-green-700">Search</.button>
            <.button type="button" phx-click="clear_search" class="bg-gray-500 hover:bg-gray-600">
              Clear
            </.button>
          </:actions>
        </.simple_form>
        
    <!-- Search Results -->
        <div :if={@search_results != []} class="mt-6">
          <h4 class="text-md font-medium text-green-900 mb-3">Search Results</h4>
          <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            <div
              :for={channel <- @search_results}
              class="p-4 bg-white rounded-lg border border-green-200 shadow-sm"
            >
              <div class="flex justify-between items-start mb-2">
                <h5 class="font-semibold text-gray-900">#{channel.name}</h5>
                <span class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                  {channel.member_count} members
                </span>
              </div>
              <p :if={channel.description} class="text-sm text-gray-600 mb-3">
                {channel.description}
              </p>
              <.button
                phx-click="join_channel"
                phx-value-id={channel.id}
                class="w-full bg-green-600 hover:bg-green-700 text-sm"
              >
                Join Channel
              </.button>
            </div>
          </div>
        </div>
      </div>

      <div class="grid gap-8 lg:grid-cols-2">
        <!-- My Channels -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">
            My Channels ({length(@user_channels)})
          </h2>
          <div :if={@user_channels == []} class="text-center py-8 text-gray-500">
            <.icon name="hero-chat-bubble-left-right" class="h-12 w-12 mx-auto mb-2 text-gray-300" />
            <p>You haven't joined any channels yet.</p>
            <p class="text-sm">Create a new channel or search for existing ones to get started!</p>
          </div>

          <div class="space-y-3">
            <div
              :for={channel <- @user_channels}
              class="p-4 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow"
            >
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-1">
                    <h3 class="font-semibold text-gray-900">#{channel.name}</h3>
                    <span
                      :if={!channel.is_public}
                      class="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded"
                    >
                      Private
                    </span>
                    <span
                      :if={channel.creator_id == @current_user.id}
                      class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded"
                    >
                      Creator
                    </span>
                  </div>
                  <p :if={channel.description} class="text-sm text-gray-600 mb-2">
                    {channel.description}
                  </p>
                  <div class="flex items-center gap-4 text-xs text-gray-500">
                    <span>{channel.member_count} members</span>
                    <span>Created {Calendar.strftime(channel.inserted_at, "%b %d, %Y")}</span>
                  </div>
                </div>

                <div class="flex gap-2 ml-4">
                  <.link
                    navigate={~p"/chat?channel=#{channel.id}"}
                    class="inline-flex items-center px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700"
                  >
                    <.icon name="hero-chat-bubble-left" class="h-4 w-4 mr-1" /> Chat
                  </.link>
                  <.button
                    :if={channel.creator_id != @current_user.id}
                    phx-click="leave_channel"
                    phx-value-id={channel.id}
                    data-confirm="Are you sure you want to leave this channel?"
                    class="px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700"
                  >
                    Leave
                  </.button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Available Public Channels -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">
            Available Public Channels ({length(@available_channels)})
          </h2>
          <div :if={@available_channels == []} class="text-center py-8 text-gray-500">
            <.icon name="hero-globe-alt" class="h-12 w-12 mx-auto mb-2 text-gray-300" />
            <p>No public channels available to join.</p>
            <p class="text-sm">You're already a member of all public channels!</p>
          </div>

          <div class="space-y-3">
            <div
              :for={channel <- @available_channels}
              class="p-4 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow"
            >
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <h3 class="font-semibold text-gray-900 mb-1">#{channel.name}</h3>
                  <p :if={channel.description} class="text-sm text-gray-600 mb-2">
                    {channel.description}
                  </p>
                  <div class="flex items-center gap-4 text-xs text-gray-500">
                    <span>{channel.member_count} members</span>
                    <span>Created {Calendar.strftime(channel.inserted_at, "%b %d, %Y")}</span>
                  </div>
                </div>

                <.button
                  phx-click="join_channel"
                  phx-value-id={channel.id}
                  class="ml-4 px-4 py-2 bg-green-600 text-white text-sm rounded hover:bg-green-700"
                >
                  Join
                </.button>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Back to Chat Link -->
      <div class="mt-8 text-center">
        <.link navigate={~p"/chat"} class="text-blue-600 hover:text-blue-800 underline">
          ← Back to Chat
        </.link>
      </div>
    </div>
    """
  end

  def handle_event("toggle_create_form", _params, socket) do
    {:noreply, assign(socket, show_create_form: !socket.assigns.show_create_form)}
  end

  def handle_event("toggle_search", _params, socket) do
    {:noreply, assign(socket, show_search: !socket.assigns.show_search)}
  end

  def handle_event("create_channel", %{"channel" => channel_params}, socket) do
    channel_attrs =
      Map.merge(channel_params, %{
        "creator_id" => socket.assigns.current_user.id,
        "is_public" => Map.get(channel_params, "is_public", "false") == "true"
      })

    case Channels.create_channel(channel_attrs) do
      {:ok, channel} ->
        # Refresh the user's channels list
        user_channels = Channels.list_user_channels(socket.assigns.current_user.id)

        available_channels =
          Channels.list_available_channels_for_user(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(user_channels: user_channels, available_channels: available_channels)
         |> assign(show_create_form: false, create_form: to_form(%{}, as: "channel"))
         |> put_flash(:info, "Channel '#{channel.name}' created successfully!")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(create_form: to_form(changeset, as: "channel"))
         |> put_flash(:error, "Failed to create channel. Please check the form.")}
    end
  end

  def handle_event("search_channels", %{"search" => %{"term" => term}}, socket) do
    search_results =
      if String.trim(term) != "" do
        Channels.search_public_channels(String.trim(term))
      else
        []
      end

    {:noreply, assign(socket, search_results: search_results, search_term: term)}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply,
     assign(socket, search_results: [], search_term: "", search_form: to_form(%{}, as: "search"))}
  end

  def handle_event("join_channel", %{"id" => channel_id}, socket) do
    {channel_id, _} = Integer.parse(channel_id)

    case Channels.add_user_to_channel(socket.assigns.current_user.id, channel_id) do
      {:ok, :joined} ->
        channel = Channels.get_channel!(channel_id)

        # Refresh the channels lists
        user_channels = Channels.list_user_channels(socket.assigns.current_user.id)

        available_channels =
          Channels.list_available_channels_for_user(socket.assigns.current_user.id)

        # Clear search results to refresh them
        search_results =
          if socket.assigns.search_term != "" do
            Channels.search_public_channels(socket.assigns.search_term)
          else
            []
          end

        {:noreply,
         socket
         |> assign(
           user_channels: user_channels,
           available_channels: available_channels,
           search_results: search_results
         )
         |> put_flash(:info, "Successfully joined '#{channel.name}'!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to join channel.")}
    end
  end

  def handle_event("leave_channel", %{"id" => channel_id}, socket) do
    {channel_id, _} = Integer.parse(channel_id)

    case Channels.remove_user_from_channel(socket.assigns.current_user.id, channel_id) do
      {:ok, _} ->
        channel = Channels.get_channel!(channel_id)

        # Refresh the channels lists
        user_channels = Channels.list_user_channels(socket.assigns.current_user.id)

        available_channels =
          Channels.list_available_channels_for_user(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(user_channels: user_channels, available_channels: available_channels)
         |> put_flash(:info, "Left channel '#{channel.name}'")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "You are not a member of this channel.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to leave channel.")}
    end
  end
end
