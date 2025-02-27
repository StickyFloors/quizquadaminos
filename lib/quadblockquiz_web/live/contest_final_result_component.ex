defmodule QuadblockquizWeb.ContestFinalResultComponent do
  use QuadblockquizWeb, :live_component

  alias Quadblockquiz.Contests

  def render(assigns) do
    ~L"""
    <h1>Contestboard</h1>
      <table>
      <tr>
      <th>Player</th>
      <th class="pointer" phx-click="sort" phx-value-param="score" phx-target="<%= @myself %>">Score</th>
      <th class="pointer" phx-click="sort" phx-value-param="dropped_bricks" phx-target="<%= @myself %>">Bricks</th>
      <th class="pointer" phx-click="sort" phx-value-param="correctly_answered_qna" phx-target="<%= @myself %>">Questions</th>
      <th>Start time</th>
      <th>End time</th>
      </tr>

      <%= for record <- @contest_records do %>
       <tr>
      <td><%= user_name(record) %></td>
      <td><%= record.score %></td>
      <td><%= record.dropped_bricks %></td>
      <td><%= record.correctly_answered_qna %></td>
      <td><%= truncate_date(record.start_time) %></td>
      <td><%= truncate_date(record.end_time) %></td>

      </tr>
      <% end %>
      </table>
      <%= unless active_contest?(@contest.name) do %>
      <%= for i <- (@page - 5)..(@page + 5), i >0 do %>
      <%= live_patch i, class: "button button-outline", to: Routes.contests_path(@socket, :show, @contest, page: i, sort_by: @sort_by)%>
       <% end %>
       <% end %>
    """
  end

  def update(assigns, socket) do
    records =
      if active_contest?(assigns.contest.name) do
        assigns.contest_records
      else
        Contests.contest_game_records(assigns.contest, assigns.page, assigns.sort_by)
      end

    {:ok,
     assign(socket,
       contest_records: records,
       contest: assigns.contest,
       page: assigns[:page],
       sort_by: assigns[:sort_by]
     )}
  end

  def handle_event("sort", %{"param" => sort_by}, socket) do
    contest = socket.assigns.contest

    socket = socket |> assign(sort_by: sort_by)

    params = [sort_by: sort_by]

    {:noreply,
     socket
     |> push_patch(
       to:
         Routes.contests_path(
           socket,
           :show,
           contest,
           if(active_contest?(contest.name), do: params, else: params ++ [page: 1])
         )
     )}
  end

  def truncate_date(nil) do
    nil
  end

  def truncate_date(date) do
    DateTime.truncate(date, :second)
  end

  defp active_contest?(name) do
    name = String.to_atom(name)
    :ets.whereis(name) != :undefined
  end

  defp user_name(record) do
    case record do
      %Quadblockquiz.GameBoard{} ->
        record.user.name

      _ ->
        case Quadblockquiz.Accounts.get_user(record.uid) do
          nil -> "Anonymous"
          user -> user.name
        end
    end
  end
end
