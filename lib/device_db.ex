defmodule Ssdp.DeviceDb do
  use GenServer

  def child_spec() do
    %{
      id: Ssdp.DeviceDb,
      name: Ssdp.DeviceDb,
      start: {Ssdp.DeviceDb, :start_link, %{}}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def get_all() do
    GenServer.call(Ssdp.DeviceDb, :get)
  end

  def add(packet) do
    if Map.has_key?(packet, :nt) do
      if Map.has_key?(packet, :usn) do
        GenServer.cast(Ssdp.DeviceDb, {:add, packet})
      end
    end
  end

  def update(packet) do
    if Map.has_key?(packet, :nt) do
      if Map.has_key?(packet, :usn) do
        GenServer.cast(Ssdp.DeviceDb, {:update, packet})
      end
    end
  end

  def delete(packet) do
    if Map.has_key?(packet, :nt) do
      if Map.has_key?(packet, :usn) do
        GenServer.cast(Ssdp.DeviceDb, {:delete, packet})
      end
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add, packet}, state) do
    {:noreply, Map.update(
      state,                        # current state (to be updated)
      packet.nt,                    # key (device- or service-type)
      %{ packet.usn => packet },    # in case there's no such entry
      fn old_state -> Map.update(   # if there's already a map for this nt
        old_state,        # old nt-map (to be updated)
        packet.usn,       # key (unique id of this device/service)
        packet,           # in case this usn is not yet present
        fn _old_packet -> packet end) # otherwise we simply replace it
      end
      )}
  end

  def handle_cast({:update, _packet}, state) do
    IO.puts("Updating DB")
    {:noreply, state}
  end

  def handle_cast({:delete, _packet}, state) do
    IO.puts("Deleting from DB")
    {:noreply, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
