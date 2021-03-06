defmodule RethinkDocs.RoomChannel do
  use Phoenix.Channel
  import RethinkDB.Query
  alias RethinkDocs.Presence

  def join("rooms:lobby", _message, socket) do
    send(self, {:after_join, _message})
    {:ok, socket}
  end

  def handle_info({:after_join, _message}, socket) do
    Presence.track(socket, socket.assigns.user, %{
      online_at: :os.system_time(:milli_seconds)
    })
    push socket, "presence_state", Presence.list(socket)

    posts = table("posts") |> RethinkDocs.Database.run
    push socket, "new_posts", %{value: posts.data}

    {:noreply, socket}
  end

  def handle_in("new:msg", msg, socket) do
    result = table("posts")
    |> insert(%{text: msg["body"]})
    |> RethinkDocs.Database.run

    {:reply, {:ok, msg["body"]}, socket}
  end

  def join("rooms:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
