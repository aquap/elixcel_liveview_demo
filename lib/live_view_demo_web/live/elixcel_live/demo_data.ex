defmodule ElixcelLive.DemoData do
  @initial_cells %{
    [2, 1] => %{value: "Quantity", format: %{bold: true}},
    [3, 1] => %{value: "Price", format: %{bold: true}},
    [4, 1] => %{value: "Total", format: %{bold: true}},
    [1, 2] => %{value: "Apples"},
    [2, 2] => %{value: "4"},
    [3, 2] => %{value: "2"},
    [4, 2] => %{value: "= B2 * C2"},
    [1, 3] => %{value: "Bananas"},
    [2, 3] => %{value: "5"},
    [3, 3] => %{value: "3"},
    [4, 3] => %{value: "= B3 * C3"},
    [1, 4] => %{value: "Pears"},
    [2, 4] => %{value: "6"},
    [3, 4] => %{value: "5"},
    [4, 4] => %{value: "= B4 * C4"},
    [4, 5] => %{value: "D2 + D3 + D4", format: %{bold: true}}
  }

  def cells() do
    @initial_cells
  end
end
