defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <table phx-keydown="keydown" phx-target="window">
      <tbody>
        <tr><td></td><td>A</td><td>B</td></tr>
        <%= for {row, row_index} <- rows(@sheet) do %>
          <tr>
            <td><%= row_index + 1 %></td>
            <%= for {cell, column_index} <- cells(row) do %>
              <td <%= active?(column_index, row_index, @current_cell) %>><%= cell %></td>
            <% end %>
           </tr>
        <% end %>
      </tbody>
    </table>

    <style>
      td { border: 1px solid #e1e1e1; }
      td.active { background-color: #dff4fb; }
    </style>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, sheet: [[nil, nil, nil], [nil, nil, nil]], current_cell: [0, 0])}
  end

  def handle_event("keydown", "ArrowRight", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column + 1, current_row])}
  end

  def handle_event("keydown", "ArrowLeft", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column - 1, current_row])}
  end

  def handle_event("keydown", "ArrowUp", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column, current_row - 1])}
  end

  def handle_event("keydown", "ArrowDown", socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column, current_row + 1])}
  end

  defp rows(_sheet) do
    Enum.with_index([["x", "x2"], ["y", "y2"]])
  end

  defp cells(row) do
    Enum.with_index(row)
  end

  defp active?(column, row, current_cell) do
    [current_column, current_row] = current_cell
    column == current_column && row == current_row && "class=active" || ""
  end

end
