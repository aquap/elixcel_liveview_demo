defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  use Ecto.Schema

  embedded_schema do
    field :value, :string
  end

  def render(assigns) do
    ~L"""

    <h1 class="float-left">Elixcel</h1>
    <div class="float-left row mt-3 ml-5">
      <a href="#" phx-click="bold" class="btn btn-outline-secondary btn-sm"><strong>Bold</strong></a>
      <a href="#" phx-click="italics" class="btn btn-outline-secondary btn-sm ml-1"><em>Italics</em></a>
    </div>
    <div class="float-right row mt-3">
      <a href="#" phx-click="add-row" class="btn btn-outline-success btn-sm">Add Row</a><br>
      <a href="#" phx-click="add-col" class="btn btn-outline-success btn-sm ml-2 mr-3">Add Column</a>
    </div>

    <table phx-keydown="keydown" phx-keyup="keyup" phx-target="window" class="table table-bordered">
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

    <style>
      table { table-layout: fixed; }
      td.border { background-color: #eee; text-align: center; }
      td.border.selected { background-color: #ddd; }
      td.active { background-color: #dff4fb; }
      td.active.editing { background-color: white; }
      td input { border: none; }
    </style>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, rows: 6, cols: 6, current_cell: [1, 1], cells: %{}, editing: false)}
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
  def handle_event("keydown", %{"code" => "ArrowLeft"}, %{assigns: %{editing: false}} = socket) do
    {:noreply, assign(socket, current_cell: move(:left, socket))}
  end

  def handle_event("keydown", %{"code" => "ArrowRight"}, %{assigns: %{editing: false}} = socket) do
    {:noreply, assign(socket, current_cell: move(:right, socket))}
  end

  def handle_event("keydown", %{"code" => "ArrowUp"}, %{assigns: %{editing: false}} = socket) do
    {:noreply, assign(socket, current_cell: move(:up, socket))}
  end

  def handle_event("keydown", %{"code" => "ArrowDown"}, %{assigns: %{editing: false}} = socket) do
    {:noreply, assign(socket, current_cell: move(:down, socket))}
  end

  # Navigation with the arrow keys - when editing we save the edited value and move
  def handle_event("keyup", %{"code" => "ArrowLeft"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:left, socket),
       editing: false,
       cells: updated_cells(socket),
       edited_value: nil
     )}
  end

  def handle_event("keyup", %{"code" => "ArrowRight"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:right, socket),
       editing: false,
       cells: updated_cells(socket),
       edited_value: nil
     )}
  end

  def handle_event("keyup", %{"code" => "ArrowUp"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:up, socket),
       editing: false,
       cells: updated_cells(socket),
       edited_value: nil
     )}
  end

  def handle_event("keyup", %{"code" => "ArrowDown"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:down, socket),
       editing: false,
       cells: updated_cells(socket),
       edited_value: nil
     )}
  end

  def handle_event("keydown", %{"key" => "b", "metaKey" => true}, %{assigns: %{editing: false}} = socket) do
    toggle_format(socket, :bold)
  end

  def handle_event("keydown", %{"key" => "i", "metaKey" => true}, %{assigns: %{editing: false}} = socket) do
    toggle_format(socket, :italics)
  end

  # Pressing an alpha-numeric key will enter the edit mode
  def handle_event("keyup", %{"key" => key}, socket) do
    if String.match?(key, ~r/^[[:alnum:]]$/u) do
      {:noreply, assign(socket, editing: true, changeset: changeset(key))}
    else
      {:noreply, socket}
    end
  end

  # Fallback
  def handle_event("keydown", _, socket), do: {:noreply, socket}

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

  # Add a row to the sheet
  def handle_event("add-row", _, socket) do
    {:noreply, assign(socket, rows: socket.assigns.rows + 1)}
  end

  # Add a column to the sheet
  def handle_event("add-col", _, socket) do
    {:noreply, assign(socket, cols: socket.assigns.cols + 1)}
  end

  # Formatting events
  def handle_event("bold", _, socket), do: toggle_format(socket, :bold)
  def handle_event("italics", _, socket), do: toggle_format(socket, :italics)

  # Private functions

  defp changeset(value) do
    %LiveViewDemoWeb.ElixcelLive{} |> Ecto.Changeset.cast(%{value: value}, [:value])
  end

  defp updated_cells(socket) do
    [current_column, current_row] = socket.assigns.current_cell

    socket.assigns.cells
    |> Map.put([current_column, current_row], %{value: socket.assigns[:edited_value]})
  end

  defp cell_value(cells, col, row) do
    cells[[col, row]][:value]
  end

  def toggle_format(socket, format) do
    [current_column, current_row] = socket.assigns.current_cell

    format_value =
      socket.assigns.cells |> get_in([[current_column, current_row], :format, format])

    cells =
      socket.assigns.cells
      |> Map.put([current_column, current_row], %{
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

  defp computed_cell_value(cells, col, row) do
    value = cells[[col, row]][:value] || ""
    computed_cell_value(cells, col, row, String.starts_with?(value, "="))
  end

  defp computed_cell_value(cells, ref) do
    [col, row] = ref_to_col_row(ref)
    computed_cell_value(cells, col, row)
  end

  defp computed_cell_value(cells, col, row, true) do
    value = String.replace(cells[[col, row]][:value], "=", "")

    # Given the string "A1 + B2" this will turn it into an array of references ie. ["A1", "B2"]
    references = Regex.scan(~r/[A-Za-z][0-9]+/, value) |> Enum.map(fn x -> Enum.at(x, 0) end)

    scope =
      references
      |> Enum.reduce(%{}, fn ref, acc ->
        Map.put(acc, ref, String.to_integer(computed_cell_value(cells, ref)))
      end)

    case Abacus.eval(value, scope) do
      {:ok, result} -> result
      {:error, _} -> "#ERR"
    end
  end

  defp computed_cell_value(cells, col, row, false) do
    cell_value(cells, col, row)
  end

  def ref_to_col_row(ref) do
    [letter | digits] = String.codepoints(ref)
    letter = letter |> String.capitalize()
    col = " ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.codepoints() |> Enum.find_index(&(&1 == letter))
    row = digits |> Enum.join("") |> String.to_integer()
    [col, row]
  end

  defp move(direction, socket) do
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
