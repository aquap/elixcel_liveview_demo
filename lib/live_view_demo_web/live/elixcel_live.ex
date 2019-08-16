defmodule LiveViewDemoWeb.ElixcelLive do
  use Phoenix.LiveView
  import Calendar.Strftime

  def render(assigns) do
    ~L"""
    <table>
      <tbody>
        <tr><td></td><td>A</td><td>B</td></tr>
        <tr><td>1</td><td></td><td></td></tr>
        <tr><td>2</td><td></td><td></td></tr>
      </tbody>
    </table>

    <style>
      td { border: 1px solid #e1e1e1; }
    </style>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  defp put_date(socket) do
    assign(socket, date: :calendar.local_time())
  end
end
