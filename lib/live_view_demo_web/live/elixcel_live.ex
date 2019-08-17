defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <table phx-keydown="keydown" phx-target="window">
      <tbody>
        <tr>
          <td></td>
          <%= for {col, col_index} <- cols(@sheet) do %>
            <td class="border"><%= List.to_string([?A + col_index]) %></td>
          <%= end %>
        </tr>
        <%= for {row, row_index} <- rows(@sheet) do %>
          <tr>
            <td class="border <%= selected_row_class(row_index, @current_cell) %>"><%= row_index + 1 %></td>
            <%= for {cell, column_index} <- cells(row) do %>
              <td <%= active?(column_index, row_index, @current_cell, @edit_mode) %>><%= cell %></td>
            <% end %>
           </tr>
        <% end %>
      </tbody>
    </table>

    <style>
      td { border: 0.5px solid #bbb; }
      td.border { background-color: #eee; text-align: center; }
      td.border.selected { background-color: #ccc;  }
      td.active { border-color: #4b89ff; background-color: #dff4fb; }
    </style>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, sheet: [[nil, nil, nil], [nil, nil, nil]], current_cell: [0, 0], edit_mode: false)}
  end

  def handle_event("keydown", "ArrowRight", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column + 1, current_row])}
  end

  def handle_event("keydown", "ArrowLeft", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [max(current_column - 1, 0), current_row])}
  end

  def handle_event("keydown", "ArrowUp", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column, max(current_row - 1, 0)])}
  end

  def handle_event("keydown", "ArrowDown", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column, current_row + 1])}
  end

  def handle_event("keydown", "Enter", socket) do
    {:noreply, assign(socket, edit_mode: !socket.assigns.edit_mode)}
  end

  def handle_event("keydown", _key, socket), do: {:noreply, socket}

  defp rows(sheet) do
    Enum.with_index(sheet)
  end

  def cols(sheet) do
    [first_row, _] = sheet
    Enum.with_index(first_row)
  end

  defp cells(row) do
    Enum.with_index(row)
  end

  defp active?(column, row, current_cell, true) do
    [current_column, current_row] = current_cell
    column == current_column && row == current_row && "contenteditable=true class=active" || ""
  end

  defp active?(column, row, current_cell, false) do
    [current_column, current_row] = current_cell
    column == current_column && row == current_row && "class=active" || ""
  end

  defp selected_row_class(row, [_, row]), do: "selected"
  defp selected_row_class(_, _), do: ""
end
