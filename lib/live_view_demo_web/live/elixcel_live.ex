defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  use Ecto.Schema

  embedded_schema do
    field :value, :string
  end

  def render(assigns) do
    ~L"""
    <table phx-keydown="keydown" phx-keyup="keyup" phx-target="window">
      <tbody>
        <tr>
          <td></td>
          <%= for {_col, col_index} <- cols(@sheet) do %>
            <td class="border <%= selected_col_class(col_index, @current_cell) %>"><%= List.to_string([?A + col_index]) %></td>
          <% end %>
        </tr>
        <%= for {row, row_index} <- rows(@sheet) do %>
          <tr>
            <td class="border <%= selected_row_class(row_index, @current_cell) %>"><%= row_index + 1 %></td>
            <%= for {cell, column_index} <- cells(row) do %>
              <td phx-click="goto-cell" phx-value-column="<%= column_index %>" phx-value-row="<%= row_index %>" class="<%= active_class(column_index, row_index, @current_cell) %>">
                <%= if @editing && [column_index, row_index] == @current_cell && @changeset do %>
                  <%= f = form_for @changeset, "#", [phx_change: :change,  phx_submit: :save] %>
                    <%= text_input f, :value, "phx-hook": "SetFocus" %>
                  </form>
                <% else %>
                  <%= cell %>
                <% end %>
              </td>
            <% end %>
           </tr>
        <% end %>
      </tbody>
    </table>

    <a href="#" phx-click="add-row">Add Row</a><br>
    <a href="#" phx-click="add-col">Add Column</a>

    <style>
      td { border: 0.5px solid #bbb; width: 120px; }
      td.border { background-color: #eee; text-align: center; }
      td.border.selected { background-color: #ddd;  }
      td.active { border-color: #4b89ff; background-color: #dff4fb; }
      form, input { padding: 0 !important; margin: 0 !important; border: none !important; height: inherit !important; width: inherit !important; font-size: 1em; }
    </style>
    """
  end

  def mount(_session, socket) do
    {:ok,
     assign(socket,
       sheet: [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]],
       current_cell: [0, 0],
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
    {:noreply, assign(socket, editing: false, sheet: updated_sheet(socket), edited_value: nil)}
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
       sheet: updated_sheet(socket),
       edited_value: nil
     )}
  end

  def handle_event("keyup", %{"code" => "ArrowRight"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:right, socket),
       editing: false,
       sheet: updated_sheet(socket),
       edited_value: nil
     )}
  end

  def handle_event("keyup", %{"code" => "ArrowUp"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:up, socket),
       editing: false,
       sheet: updated_sheet(socket),
       edited_value: nil
     )}
  end

  def handle_event("keyup", %{"code" => "ArrowDown"}, %{assigns: %{editing: true}} = socket) do
    {:noreply,
     assign(socket,
       current_cell: move(:down, socket),
       editing: false,
       sheet: updated_sheet(socket),
       edited_value: nil
     )}
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
  def handle_event("save", params, socket), do: {:noreply, socket}

  # Other events

  # Goto a cell when it is clicked
  def handle_event("goto-cell", %{"column" => column, "row" => row}, socket) do
    {:noreply, assign(socket, current_cell: [String.to_integer(column), String.to_integer(row)])}
  end

  # Add a row to the sheet
  def handle_event("add-row", _, socket) do
    new_row = List.duplicate(nil, number_of_columns(socket.assigns.sheet))
    {:noreply, assign(socket, sheet: socket.assigns.sheet ++ [new_row])}
  end

  # Add a column to the sheet
  def handle_event("add-col", _, socket) do
    sheet = socket.assigns.sheet |> Enum.map(fn row -> row ++ [nil] end)
    {:noreply, assign(socket, sheet: sheet)}
  end

  # Private functions

  defp changeset(value) do
    %LiveViewDemoWeb.ElixcelLive{} |> Ecto.Changeset.cast(%{value: value}, [:value])
  end

  defp updated_sheet(socket) do
    [current_column, current_row] = socket.assigns.current_cell

    new_row =
      socket.assigns.sheet
      |> Enum.at(current_row)
      |> List.update_at(current_column, fn _ -> socket.assigns[:edited_value] end)

    socket.assigns.sheet |> List.update_at(current_row, fn _ -> new_row end)
  end

  defp current_cell_value(socket) do
    [current_column, current_row] = socket.assigns.current_cell
    socket.assigns.sheet |> Enum.at(current_row) |> Enum.at(current_column)
  end

  defp move(direction, socket) do
    [current_column, current_row] = socket.assigns.current_cell

    case direction do
      :left ->
        [max(current_column - 1, 0), current_row]

      :right ->
        [min(current_column + 1, number_of_columns(socket.assigns.sheet) - 1), current_row]

      :up ->
        [current_column, max(current_row - 1, 0)]

      :down ->
        [current_column, min(current_row + 1, number_of_rows(socket.assigns.sheet) - 1)]
    end
  end

  defp rows(sheet), do: Enum.with_index(sheet)
  defp cols(sheet), do: sheet |> List.first() |> Enum.with_index()
  defp cells(row), do: Enum.with_index(row)

  defp number_of_rows(sheet), do: sheet |> length
  defp number_of_columns(sheet), do: sheet |> List.first() |> length

  defp active_class(column, row, [column, row]), do: "active"
  defp active_class(_, _, _), do: ""

  defp selected_col_class(col, [col, _]), do: "selected"
  defp selected_col_class(_, _), do: ""

  defp selected_row_class(row, [_, row]), do: "selected"
  defp selected_row_class(_, _), do: ""
end
