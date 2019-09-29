defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  use Ecto.Schema

  embedded_schema do
    field :value, :string
  end

  @arrow_left %{"code" => "ArrowLeft"}
  @arrow_right %{"code" => "ArrowRight"}
  @arrow_up %{"code" => "ArrowUp"}
  @arrow_down %{"code" => "ArrowDown"}
  @tab %{"code" => "Tab"}
  @backspace %{"code" => "Backspace"}
  @meta_b %{"key" => "b", "metaKey" => true}
  @ctrl_b %{"key" => "b", "ctrlKey" => true}
  @meta_i %{"key" => "i", "metaKey" => true}
  @ctrl_i %{"key" => "i", "ctrlKey" => true}

  def render(assigns) do
    ~L"""

    <h1 class="float-left">Elixcel</h1>
    <div class="float-left row mt-3 ml-5">
      <a href="#" phx-click="bold" class="btn btn-outline-secondary btn-sm"><strong>Bold</strong></a>
      <a href="#" phx-click="italics" class="btn btn-outline-secondary btn-sm ml-1"><em>Italics</em></a>
    </div>
    <div class="float-right row mt-3">
      <a href="#" phx-click="clear-sheet" class="btn btn-outline-secondary btn-sm mr-4">Clear sheet</a>
      <a href="#" phx-click="add-row" class="btn btn-outline-success btn-sm">Add Row</a><br>
      <a href="#" phx-click="add-col" class="btn btn-outline-success btn-sm ml-2 mr-3">Add Column</a>
    </div>

    <table phx-keydown="keydown" phx-keyup="keyup" phx-target="window" class="table table-bordered" <%= @editing && "editing" || "" %>>
      <tbody>
        <tr>
          <td></td>
          <%= for col <- (1..@cols) do %>
            <td class="border <%= selected_col_class(col, @current_cell) %>"><%= List.to_string([?A + col - 1]) %></td>
          <% end %>
        </tr>
        <%= for row <- (1..@rows) do %>
          <tr>
            <td class="border <%= selected_row_class(row, @current_cell) %>"><%= row %></td>
            <%= for col <- (1..@cols) do %>
              <td phx-click="goto-cell" phx-value-column="<%= col %>" phx-value-row="<%= row %>" class="<%= active_class(col, row, @current_cell) %> <%= @editing && [col, row] == @current_cell && "editing" %>">
                <%= if @editing && [col, row] == @current_cell && @changeset do %>
                  <%= f = form_for @changeset, "#", [phx_change: :change,  phx_submit: :save] %>
                    <%= text_input f, :value, "phx-hook": "SetFocus" %>
                  </form>
                <% else %>
                  <%= cond do %>
                  <%= cell_bold?(@cells, col, row) -> %>
                    <strong><%= computed_cell_value(@cells, col, row) %></strong>
                  <% cell_italics?(@cells, col, row) -> %>
                    <em><%= computed_cell_value(@cells, col, row) %></em>
                  <% true -> %>
                    <%= computed_cell_value(@cells, col, row) %>
                  <% end %>
                <% end %>
              </td>
            <% end %>
           </tr>
        <% end %>
      </tbody>
    </table>

    <ul class="list-unstyled" id="help-text">
      <li>Navigate using the arrow keys</li>
      <li>Enter a string or a number by using the keyboard</li>
      <li>Edit an existing cell by pressing Enter</li>
      <li>Discard changes to a cell by pressing Escape</li>
      <li>Delete a cell by pressing Backspace</li>
      <li>Toggle <strong>bold</strong>/<em>italics</em> with Cmd+b/Ctrl+b or Cmd+i/Ctrl+i</li>
      <li>Mathematical expressions must start with an equal(=) sign and can reference other cells ie. <code>= B2 * C2 + 10</code></li>
    </ul>

    <style>
      table { table-layout: fixed; }
      td.border { background-color: #eee; text-align: center; }
      td.border.selected { background-color: #ddd; }
      td.active { background-color: #dff4fb; }
      td.active.editing { background-color: white; }
      td input { border: none; }
      #help-text { opacity: 0.5 }
    </style>
    """
  end

  def mount(_session, socket) do
    {:ok,
     assign(socket,
       rows: 6,
       cols: 6,
       current_cell: [1, 1],
       cells: ElixcelLive.DemoData.cells(),
       editing: false
     )}
  end

  # Keyboard events

  # Pressing Enter when not editing will prepare a changeset with the existing value
  def handle_event("keyup", %{"code" => "Enter"}, %{assigns: %{editing: false}} = socket) do
    {:noreply,
     assign(socket,
       editing: true,
       changeset: changeset(current_cell_value(socket)),
       edited_value: current_cell_value(socket)
     )}
  end

  # Pressing Enter when editing will update the sheet with the new value
  def handle_event("keyup", %{"code" => "Enter"}, %{assigns: %{editing: true}} = socket) do
    {:noreply, assign(socket, editing: false, cells: updated_cells(socket), edited_value: nil)}
  end

  # Pressing Escape when editing will discard the changes
  def handle_event("keyup", %{"code" => "Escape"}, %{assigns: %{editing: true}} = socket) do
    {:noreply, assign(socket, editing: false, edited_value: nil)}
  end

  # Navigation with the arrow keys - when not editing we just move
  def handle_event("keydown", @arrow_left, %{assigns: %{editing: false}} = socket) do
    socket |> move(:left)
  end

  def handle_event("keydown", @arrow_right, %{assigns: %{editing: false}} = socket) do
    socket |> move(:right)
  end

  def handle_event("keydown", @arrow_up, %{assigns: %{editing: false}} = socket) do
    socket |> move(:up)
  end

  def handle_event("keydown", @arrow_down, %{assigns: %{editing: false}} = socket) do
    socket |> move(:down)
  end

  def handle_event("keydown", @tab, %{assigns: %{editing: false}} = socket) do
    socket |> move(:right)
  end

  def handle_event("keydown", @backspace, %{assigns: %{editing: false}} = socket) do
    socket |> clear_current_cell()
  end

  # Navigation with the arrow keys - when editing we save the edited value and move
  def handle_event("keyup", @arrow_left, %{assigns: %{editing: true}} = socket) do
    socket |> save_and_move(:left)
  end

  def handle_event("keyup", @arrow_right, %{assigns: %{editing: true}} = socket) do
    socket |> save_and_move(:right)
  end

  def handle_event("keyup", @arrow_up, %{assigns: %{editing: true}} = socket) do
    socket |> save_and_move(:up)
  end

  def handle_event("keyup", @arrow_down, %{assigns: %{editing: true}} = socket) do
    socket |> save_and_move(:down)
  end

  def handle_event("keyup", @tab, %{assigns: %{editing: true}} = socket) do
    socket |> save_and_move(:right)
  end

  # Formatting events
  def handle_event("bold", _, socket), do: toggle_format(socket, :bold)

  def handle_event("keydown", @meta_b, %{assigns: %{editing: false}} = socket) do
    toggle_format(socket, :bold)
  end

  def handle_event("keyup", @ctrl_b, %{assigns: %{editing: false}} = socket) do
    toggle_format(socket, :bold)
  end

  def handle_event("italics", _, socket), do: toggle_format(socket, :italics)

  def handle_event("keydown", @meta_i, %{assigns: %{editing: false}} = socket) do
    toggle_format(socket, :italics)
  end

  def handle_event("keyup", @ctrl_i, %{assigns: %{editing: false}} = socket) do
    toggle_format(socket, :italics)
  end

  # Pressing an alpha-numeric key will enter the edit mode
  def handle_event("keyup", %{"key" => key}, %{assigns: %{editing: false}} = socket) do
    if String.match?(key, ~r/^[[:alnum:]=]$/u) do
      {:noreply, assign(socket, editing: true, changeset: changeset(key), edited_value: key)}
    else
      {:noreply, socket}
    end
  end

  # Fallback
  def handle_event("keydown", _, socket), do: {:noreply, socket}
  def handle_event("keyup", _, socket), do: {:noreply, socket}

  # Form events

  # Save the edited value in the state
  def handle_event("change", params, socket) do
    {:noreply, assign(socket, edited_value: params["elixcel_live"]["value"])}
  end

  # Just ignore the save event - it exists primarly to prevent a real form submit on Enter
  def handle_event("save", _params, socket), do: {:noreply, socket}

  # Other events

  # Goto a cell when it is clicked
  def handle_event("goto-cell", %{"column" => column, "row" => row}, socket) do
    {:noreply, assign(socket, current_cell: [String.to_integer(column), String.to_integer(row)])}
  end

  # Clear the sheet
  def handle_event("clear-sheet", _, socket) do
    {:noreply, assign(socket, cells: %{})}
  end

  # Add a row to the sheet
  def handle_event("add-row", _, socket) do
    {:noreply, assign(socket, rows: socket.assigns.rows + 1)}
  end

  # Add a column to the sheet
  def handle_event("add-col", _, socket) do
    {:noreply, assign(socket, cols: socket.assigns.cols + 1)}
  end

  # Private functions

  defp changeset(value) do
    %LiveViewDemoWeb.ElixcelLive{} |> Ecto.Changeset.cast(%{value: value}, [:value])
  end

  defp clear_current_cell(socket) do
    {:noreply,
     assign(socket, cells: socket.assigns.cells |> Map.delete(socket.assigns.current_cell))}
  end

  defp updated_cells(socket) do
    socket.assigns.cells
    |> Map.put(socket.assigns.current_cell, %{value: socket.assigns[:edited_value]})
  end

  defp cell_value(cells, col, row) do
    cells[[col, row]][:value]
  end

  defp toggle_format(socket, format) do
    format_value = socket.assigns.cells |> get_in([socket.assigns.current_cell, :format, format])

    cells =
      socket.assigns.cells
      |> Map.put(socket.assigns.current_cell, %{
        value: current_cell_value(socket),
        format: %{format => !format_value}
      })

    {:noreply, assign(socket, cells: cells)}
  end

  defp cell_bold?(cells, col, row) do
    cells[[col, row]][:format][:bold]
  end

  defp cell_italics?(cells, col, row) do
    cells[[col, row]][:format][:italics]
  end

  defp current_cell_value(socket) do
    [current_column, current_row] = socket.assigns.current_cell
    cell_value(socket.assigns.cells, current_column, current_row)
  end

  # Computed cell values are calculated recursively to resolve references to other cells
  defp computed_cell_value(cells, col, row, visited \\ MapSet.new()) do
    if MapSet.member?(visited, [col, row]) do
      # We have a cyclic reference - fail
      "REF#"
    else
      visited = MapSet.put(visited, [col, row])

      value = cell_value(cells, col, row)

      integer(value) || float(value) || expression(value, cells, visited) || value
    end
  end

  defp integer(value) do
    case is_binary(value) && Integer.parse(value) do
      {num, ""} -> num
      _ -> false
    end
  end

  defp float(value) do
    case is_binary(value) && Float.parse(value) do
      {num, ""} -> num
      _ -> false
    end
  end

  defp expression(value, cells, visited) do
    case is_binary(value) && String.starts_with?(value, "=") do
      true -> compute(value, cells, visited)
      _ -> false
    end
  end

  defp compute(expression, cells, visited) do
    # Remove leading =
    expression = String.replace(expression, "=", "", global: false)

    # Given the string "A1 + B2" this will turn it into an array of references ie. ["A1", "B2"]
    references = Regex.scan(~r/[A-Za-z][0-9]+/, expression) |> Enum.map(fn x -> Enum.at(x, 0) end)

    # Build a map of references and values ie.
    # %{"A1" => 2, "B2" => 14}
    scope =
      references
      |> Enum.reduce(%{}, fn ref, acc ->
        [col, row] = ref_to_col_row(ref)
        Map.put(acc, ref, computed_cell_value(cells, col, row, visited))
      end)

    # Use Abacus to calculate the actual value
    case Abacus.eval(expression, scope) do
      {:ok, result} -> result
      {:error, _} -> "#ERR"
    end
  end

  # Converts a reference like "A1" to [1, 1]
  defp ref_to_col_row(ref) do
    [letter | digits] = String.codepoints(ref)
    letter = letter |> String.capitalize()
    col = " ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.codepoints() |> Enum.find_index(&(&1 == letter))
    row = digits |> Enum.join("") |> String.to_integer()
    [col, row]
  end

  defp move(socket, direction) do
    {:noreply, assign(socket, current_cell: new_current_cell(socket, direction))}
  end

  defp save_and_move(socket, direction) do
    {:noreply,
     assign(socket,
       current_cell: new_current_cell(socket, direction),
       editing: false,
       cells: updated_cells(socket),
       edited_value: nil
     )}
  end

  defp new_current_cell(socket, direction) do
    [current_column, current_row] = socket.assigns.current_cell

    case direction do
      :left ->
        [max(current_column - 1, 1), current_row]

      :right ->
        [min(current_column + 1, socket.assigns.cols), current_row]

      :up ->
        [current_column, max(current_row - 1, 1)]

      :down ->
        [current_column, min(current_row + 1, socket.assigns.rows)]
    end
  end

  defp active_class(column, row, [column, row]), do: "active"
  defp active_class(_, _, _), do: ""

  defp selected_col_class(col, [col, _]), do: "selected"
  defp selected_col_class(_, _), do: ""

  defp selected_row_class(row, [_, row]), do: "selected"
  defp selected_row_class(_, _), do: ""
end
