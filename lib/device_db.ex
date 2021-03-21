defmodule Ssdp.DeviceDb do
  use GenServer

  def child_spec() do
    %{
      id: Ssdp.DeviceDb,
      name: Ssdp.DeviceDb,
      start: {Ssdp.DeviceDb, :start_link, []}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def add(packet) do
    GenServer.cast(Ssdp.DeviceDb, {:add, packet})
  end

  def update(packet) do
    GenServer.cast(Ssdp.DeviceDb, {:update, packet})
  end

  def delete(packet) do
    GenServer.cast(Ssdp.DeviceDb, {:delete, packet})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add, packet}, state) do
    IO.puts("Adding to DB")
    {:noreply, [packet | state]}
  end

  def handle_cast({:update, _packet}, state) do
    IO.puts("Updating DB")
    {:noreply, state}
  end

  def handle_cast({:delete, packet}, state) do
    IO.puts("Deleting from DB")
    {:noreply, state}
  end
end
