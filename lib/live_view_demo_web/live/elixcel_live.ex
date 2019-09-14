defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  use Ecto.Schema
  embedded_schema do
    field :value, :string
  end

  def render(assigns) do
    ~L"""
    <table phx-keydown="keydown" phx-target="window">
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
                  <%= f = form_for @changeset, "#", [phx_change: :validate, phx_submit: :save] %>
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
    {:ok, assign(socket, sheet: [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]], current_cell: [0, 0], editing: false)}
  end



  # Ignore navigation keydown events when editing
  def handle_event("keydown", _, %{assigns: %{editing: true}} = socket), do: {:noreply, socket}

  # Keydown events - navigation with the arrow keys and toggling editing with the enter key
  def handle_event("keydown", %{"code" => "Enter"}, socket) do
    {:noreply, assign(socket, editing: true, changeset: changeset(current_cell_value(socket)))}
  end

  def handle_event("keydown", %{"code" => "ArrowLeft"}, socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [max(current_column - 1, 0), current_row])}
  end

  def handle_event("keydown", %{"code" => "ArrowRight"}, socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [min(current_column + 1, number_of_columns(socket.assigns.sheet) - 1), current_row])}
  end

  def handle_event("keydown", %{"code" => "ArrowUp"}, socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column, max(current_row - 1, 0)])}
  end

  def handle_event("keydown", %{"code" => "ArrowDown"}, socket) do
    [current_column, current_row] = socket.assigns.current_cell
    {:noreply, assign(socket, current_cell: [current_column, min(current_row + 1, number_of_rows(socket.assigns.sheet) - 1)])}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    if String.match?(key, ~r/^[[:alnum:]]$/u) do
      {:noreply, assign(socket, editing: true, changeset: changeset(key))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save", params, socket) do
    new_value = params["elixcel_live"]["value"]
    [current_column, current_row] = socket.assigns.current_cell
    new_row = socket.assigns.sheet |> Enum.at(current_row) |> List.update_at(current_column, fn _ -> new_value end)
    new_sheet = socket.assigns.sheet |> List.update_at(current_row, fn _ -> new_row end)
    {:noreply, assign(socket, editing: false, sheet: new_sheet)}
  end

  def handle_event("validate", _, socket), do: {:noreply, socket}

  # Other events

  def handle_event("goto-cell", %{"column" => column, "row" => row}, socket) do
    {:noreply, assign(socket, current_cell: [String.to_integer(column), String.to_integer(row)])}
  end

  def handle_event("add-row", _, socket) do
    new_row = List.duplicate(nil, number_of_columns(socket.assigns.sheet))
    {:noreply, assign(socket, sheet: socket.assigns.sheet ++ [new_row])}
  end

  def handle_event("add-col", _, socket) do
    sheet = socket.assigns.sheet |> Enum.map(fn row -> row ++ [nil] end)
    {:noreply, assign(socket, sheet: sheet)}
  end


  # Private functions
  defp changeset(value) do
    %LiveViewDemoWeb.ElixcelLive{} |> Ecto.Changeset.cast(%{value: value}, [:value])
  end

  defp current_cell_value(socket) do
    [current_column, current_row] = socket.assigns.current_cell
    socket.assigns.sheet |> Enum.at(current_row) |> Enum.at(current_column)
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
