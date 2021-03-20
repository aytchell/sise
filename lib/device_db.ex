defmodule DeviceDb do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def add(pid, packet) do
    GenServer.cast(pid, {:add, packet})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add, packet}, state) do
    {:noreply, [packet | state]}
  end
end
