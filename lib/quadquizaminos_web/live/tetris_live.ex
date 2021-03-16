

defmodule QuadquizaminosWeb.TetrisLive do
  use Phoenix.LiveView
  import Phoenix.HTML, only: [raw: 1]

  import QuadquizaminosWeb.LiveHelpers
  alias QuadquizaminosWeb.Router.Helpers, as: Routes
  alias Quadquizaminos.QnA

  alias Quadquizaminos.Tetris

  @debug false
  @box_width 20
  @box_height 20

  @drop_speeds [ %{name: "full throttle", ratio: 1}, # 20/s, 50 ms
                 %{name: "high speed", ratio: 2},    # 10/s, 100 ms
                 %{name: "fast", ratio: 5},          # 4/s, 250 ms. - default game starts with
                 %{name: "moderate", ratio: 7},      # ~3/s, 350 ms
                 %{name: "leisurely", ratio: 10},    # 2/s, 500 ms
                 %{name: "sedate", ratio: 15},       # 3/2s, 750 ms
                 %{name: "lethargic", ratio: 20}     # 1/s, 1000 ms
                  ]


  def mount(_param, _session, socket) do
    :timer.send_interval(50, self(), :tick)

    {:ok,
     socket
     |> assign(qna: %{}, category: nil, categories: init_categories(), powers: [], coord_modal: false)
     |> assign(speed: 2, tick_count: 5)
     |> start_game()}
  end

  def render(%{state: :starting, live_action: live_action} = assigns) do
    ~L"""
    <%= if live_action == :instructions do %>
      <div class="column">
        <%= raw game_instruction() %>
      </div>
      <% else %>
        <div class ="container">
          <div class="row">
              <div class="column column-50 column-offset-25">
                <h1>Welcome to QuizQuadBlocks!</h1>
                  <button phx-click="start">Start</button>
              </div>
          </div>
        </div>
    <% end %>
    """
  end

  def render(%{state: :game_over} = assigns) do
    ~L"""
    <div class="container">
      <div class="row">
        <div class="column column-50 column-offset-25">
          <h1>Game Over</h1>
            <h2>Your score: <%= @score %></h2>
              <button phx-click="start">Play again?</button>
        </div>
      </div>
    </div>
     <%= debug(assigns) %>

    """
  end

  def render(assigns) do
    ~L"""
      <div class="container">
        <div class="row">
          <div class="column column-75">
              <div class="row">
                <div class="column column-25 column-offset-25">
                    <h1><%= @score %></h1>
                </div>
                <div class="column column-50">
                <%= if @modal do%>
                <%= live_modal @socket,  QuadquizaminosWeb.QuizModalComponent, id: 1, powers: @powers, score: @score,  modal: @modal, qna: @qna, category: @category, return_to: Routes.tetris_path(QuadquizaminosWeb.Endpoint, :tetris)%>
                <% end %>
                  <div phx-window-keydown="keydown">
                    <%= raw svg_head() %>
                    <%= for row <- [@tetromino, Map.values(@bottom)] do %>
                      <%= for {x, y, color} <- row do %>
                        <% {x, y} = to_pixels( {x, y}, @box_width, @box_height ) %>
                        <rect
                          x="<%= x+1 %>" y="<%= y+1 %>"
                          style="fill:#<%= shades(color).light %>;"
                          width="<%= @box_width - 2 %>" height="<%= @box_height - 1 %>"/>
                        <% end %>
                    <% end %>
                    <%= raw svg_foot() %>
                  </div>
                </div>
              </div>
            </div>
            <div class="column">
            <a class="button", href = <%= Routes.tetris_path(QuadquizaminosWeb.Endpoint, :instructions) %> > How to play </a>
            <br/>
            <%= if @coord_modal do %>
               <%= live_component @socket,  QuadquizaminosWeb.CoordModalComponent, id: 2, powers: @powers %>
              <% end %>
            </div>
          <br/>
        </div>
    </div>
     <%= debug(assigns) %>
    """
  end

  defp game_instruction do
    """
    <h2>How to play</h2>
        <ol>
          <li>Up arrow key rotates the blocks</li>
          <li>Left arrow key moves the blocks to the left</li>
          <li>Right arrow key moves the blocks to the right</li>
          <li>Down arrow key moves the blocks down</li>
          <li>Debug until powerups: "r" raises dropping speed</li>
          <li>Debug until powerups: "l" lowers dropping speed</li>
          <li>Debug until powerups: "c" clears bottom blocks</li>
        </ol>
    """
  end

  defp pause_game(socket) do
    assign(socket, state: :paused, modal: true)
  end

  defp start_game(socket) do
    assign(socket,
      state: :starting,
      box_width: @box_width,
      modal: false,
      box_height: @box_height
    )
  end

  defp new_game(socket) do
    assign(socket,
      state: :playing,
      score: 0,
      bottom: %{}
    )
    |> new_block
    |> show
  end

  defp raise_speed(socket) do
    speed = socket.assigns.speed - 1
    speed = if speed < 0, do: 0, else: speed
    {:ok, speed_info} = Enum.fetch(@drop_speeds, speed)
    tick_count = speed_info.ratio
    assign(socket, speed: speed, tick_count: tick_count)
  end

  defp lower_speed(socket) do
    speed = socket.assigns.speed + 1
    lowest_speed = length(@drop_speeds) - 1
    speed = if speed > lowest_speed, do: lowest_speed, else: speed
    {:ok, speed_info} = Enum.fetch(@drop_speeds, speed)
    tick_count = speed_info.ratio
    assign(socket, speed: speed, tick_count: tick_count)
  end

  defp clear_blocks(socket) do
    assign(socket, bottom: %{})
  end

  def new_block(socket) do
    brick =
      Quadquizaminos.Brick.new_random()
      |> Map.put(:location, {3, -3})

    assign(socket, brick: brick)
  end

  def show(socket) do
    brick = socket.assigns.brick

    points =
      brick
      |> Quadquizaminos.Brick.prepare()
      |> Quadquizaminos.Points.move_to_location(brick.location)
      |> Quadquizaminos.Points.with_color(color(brick))

    assign(socket, tetromino: points)
  end

  def svg_head() do
    """
    <svg
    version="1.0"
    style="background-color: #F8F8F8"
    id="Layer_1"
    xmlns="http://www.w3.org/2000/svg"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    width="200" height="400"
    viewBox="0 0 200 400"
    xml:space="preserve">
    """
  end

  def svg_foot(), do: "</svg>"

  def boxes(points_with_colors) do
    points_with_colors
    |> Enum.map(fn {x, y, color} ->
      box({x, y}, color)
    end)
    |> Enum.join("\n")
  end

  def box(point, color) do
    """
    #{square(point, shades(color).light)}
    #{triangle(point, shades(color).dark)}
    """
  end

  def square(point, shade) do
    {x, y} = to_pixels(point, 20, 20)

    """
    <rect
      x="#{x + 1}" y="#{y + 1}"
      style="fill:##{shade};"
      width="#{@box_width - 2}" height="#{@box_height - 1}"/>
    """
  end

  def triangle(point, shade) do
    {x, y} = to_pixels(point, 20, 20)
    {w, h} = {@box_width, @box_height}

    """
    <polyline
        style="fill:##{shade}"
        points="#{x + 1},#{y + 1} #{x + w},#{y + 1} #{x + w},#{y + h}" />
    """
  end

  defp to_pixels({x, y}, bw, bh), do: {(x - 1) * bw, (y - 1) * bh}

  defp shades(:red), do: %{light: "DB7160", dark: "AB574B"}
  defp shades(:blue), do: %{light: "83C1C8", dark: "66969C"}
  defp shades(:green), do: %{light: "8BBF57", dark: "769359"}
  defp shades(:orange), do: %{light: "CB8E4E", dark: "AC7842"}
  defp shades(:grey), do: %{light: "A1A09E", dark: "7F7F7E"}
  defp shades(:purple), do: %{light: "800080", dark: "4d004d"}

  defp color(%{name: :t}), do: :red
  defp color(%{name: :i}), do: :blue
  defp color(%{name: :l}), do: :green
  defp color(%{name: :o}), do: :orange
  defp color(%{name: :z}), do: :grey

  def drop(:playing, socket, fast) do
    old_brick = socket.assigns.brick

    response =
      Tetris.drop(
        old_brick,
        socket.assigns.bottom,
        color(old_brick)
      )

    bonus = if fast, do: 2, else: 0

    socket
    |> assign(
      brick: response.brick,
      bottom: response.bottom,
      score: socket.assigns.score + response.score + bonus,
      state: if(response.game_over, do: :game_over, else: :playing)
    )
    |> show
  end

  def drop(_not_playing, socket, _fast), do: socket

  def move(_direction, %{assigns: %{state: :paused}} = socket), do: socket

  def move(direction, socket) do
    socket
    |> do_move(direction)
    |> show
  end

  def do_move(%{assigns: %{brick: brick, bottom: bottom}} = socket, :left) do
    assign(socket, brick: brick |> Tetris.try_left(bottom))
  end

  def do_move(%{assigns: %{brick: brick, bottom: bottom}} = socket, :right) do
    assign(socket, brick: brick |> Tetris.try_right(bottom))
  end

  def do_move(%{assigns: %{brick: _brick, bottom: bottom}} = socket, :turn) do
    assign(socket, brick: socket.assigns.brick |> Tetris.try_spin_90(bottom))
  end

  def handle_event("choose_category", %{"category" => category}, socket) do
    categories = socket.assigns.categories
    question_position = categories[category]
    categories = increment_position(categories, category, question_position)

    {:noreply,
     socket
     |> assign(
       category: category,
       categories: categories,
       qna: QnA.question(category, question_position)
     )}
  end

  def handle_event("unpause", _, socket) do
    {:noreply, socket |> assign(state: :playing, modal: false)}
  end

  def handle_event("keydown", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, move(:left, socket)}
  end

  def handle_event("keydown", %{"key" => "ArrowRight"}, socket) do
    {:noreply, move(:right, socket)}
  end

  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    {:noreply, move(:turn, socket)}
  end

  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    {:noreply, drop(socket.assigns.state, socket, true)}
  end

  def handle_event("keydown", %{"key" => " "}, socket) do
    {:noreply, pause_game(socket)}
  end

  ## until powerups and for debugging - take out eventually
  def handle_event("keydown", %{"key" => "l"}, socket) do
    {:noreply, lower_speed(socket)}
  end

  ## until powerups and for debugging - take out eventually
  def handle_event("keydown", %{"key" => "r"}, socket) do
    {:noreply, raise_speed(socket)}
  end

  ## until powerups and for debugging - take out eventually
  def handle_event("keydown", %{"key" => "c"}, socket) do
    {:noreply, clear_blocks(socket)}
  end

  def handle_event("keydown", _, socket), do: {:noreply, socket}

  def handle_event("start", _, socket) do
    {:noreply, new_game(socket)}
  end

  def handle_event("check_answer", %{"quiz" => %{"guess" => guess}}, socket) do
    socket =
      if correct_answer?(socket.assigns.qna, guess) do
        socket |> assign(category: nil) |> add_power() |> assign_score()
      else
        points = wrong_points(socket)
        score = socket.assigns.score - points
        score = if score < 0, do: 0, else: score
        socket = assign(socket, score: score)
        pause_game(socket)
      end
    {:noreply, socket}
  end

  def handle_event("check_answer", _params, socket), do: {:noreply, socket}

  def handle_event("powerup", %{"powerup" => "addblock"}, socket) do
    {:noreply, socket |> assign(coord_modal: true, modal: false)}
  end

  def handle_event("powerup", _, socket) do
    {:noreply, socket}
  end

  def handle_event("add_block", %{"coord" => %{"x" => x, "y" => y}}, socket) do
    {x, _} = Integer.parse(x)
    {y, _} = Integer.parse(y)
    powers = socket.assigns.powers -- [:addblock]
    bottom = socket.assigns.bottom |> Map.merge(%{{x, y} => {x, y, :purple}})

    {:noreply,
     socket |> assign(bottom: bottom, coord_modal: false, state: :playing, powers: powers)}
  end

  def handle_info(:tick, socket) do
    tick_count = socket.assigns.tick_count - 1
    if tick_count > 0 do
      ## don't drop yet
      socket = assign(socket, tick_count: tick_count)
      {:noreply, socket}
    else
      ## reset counter and drop
      {:ok, speed_info} = Enum.fetch(@drop_speeds, socket.assigns.speed)
      tick_count = speed_info.ratio

      socket = assign(socket, tick_count: tick_count)
      {:noreply, drop(socket.assigns.state, socket, false)}
    end
  end

  # defp return_to_categories_or_pause_game(true, socket) do
  #   points = right_points(socket)
  #   socket |> assign(category: nil, score: socket.assigns.score + points)
  # end

  # defp return_to_categories_or_pause_game(_, socket) do
  #   points = wrong_points(socket)
  #   score = socket.assigns.score - points
  #   score = if score < 0, do: 0, else: score
  #   socket = assign(socket, score: score)
  #   pause_game(socket)
  # end

  defp correct_answer?(%{correct: guess}, guess), do: true
  defp correct_answer?(_qna, _guess), do: false

  defp wrong_points(socket) do
    %{"Wrong" => points} = socket.assigns.qna.score
    {points, _} = Integer.parse(points)
    points
  end

  defp right_points(socket) do
    %{"Right" => points} = socket.assigns.qna.score
    {points, _} = Integer.parse(points)
    points
  end

  def debug(assigns), do: debug(assigns, @debug, Mix.env())

  def debug(assigns, true, :dev) do
    ~L"""
    <pre>
    <%= raw( @tetromino |> inspect) %>
    <%= raw( @bottom |> inspect) %>
    </pre>
    """
  end

  def debug(_assigns, _, _), do: ""

  defp init_categories do
    QnA.categories()
    |> Enum.into(%{}, fn elem -> {elem, 0} end)
  end

  defp increment_position(categories, category, current_position) do
    %{categories | category => current_position + 1}
  end

  defp assign_score(socket) do
    points = right_points(socket)
    socket |> assign(score: socket.assigns.score + points)
  end

  defp add_power(socket) do
    case socket.assigns.qna[:powerup] do
      nil ->
        socket

      power ->
        current_powers = socket.assigns.powers
        assign(socket, powers: [power | current_powers])
    end
  end
end
