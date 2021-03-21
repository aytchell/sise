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
    IO.puts("send -> add to DB")
    GenServer.cast(Ssdp.DeviceDb, {:add, packet})
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
end
