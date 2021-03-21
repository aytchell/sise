defmodule Ssdp.DeviceDb do
  use GenServer
  require Logger

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
      else
        Logger.warn("Won't add SSDP packet since it's missing 'USN'")
      end
    else
      Logger.warn("Won't add SSDP packet since it's missing 'NT'")
    end
  end

  def update(packet) do
    if Map.has_key?(packet, :nt) do
      if Map.has_key?(packet, :usn) do
        GenServer.cast(Ssdp.DeviceDb, {:update, packet})
      else
        Logger.warn("Won't update SSDP packet since it's missing 'USN'")
      end
    else
      Logger.warn("Won't update SSDP packet since it's missing 'NT'")
    end
  end

  def delete(packet) do
    if Map.has_key?(packet, :nt) do
      if Map.has_key?(packet, :usn) do
        GenServer.cast(Ssdp.DeviceDb, {:delete, packet})
      else
        Logger.warn("Won't delete SSDP packet since it's missing 'USN'")
      end
    else
      Logger.warn("Won't delete SSDP packet since it's missing 'NT'")
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add, packet}, state) do
    Logger.info("Adding SSDP packet #{inspect(packet.nt)}")
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

  def handle_cast({:update, packet}, state) do
    Logger.info("Updating SSDP packet #{inspect(packet.nt)}")
    {:noreply, Map.update(
      state,                        # current state (to be updated)
      packet.nt,                    # key (device- or service-type)
      %{ packet.usn => packet },    # in case there's no such entry
      fn old_state -> Map.update(   # if there's already a map for this nt
        old_state,        # old nt-map (to be updated)
        packet.usn,       # key (unique id of this device/service)
        packet,           # in case this usn is not yet present
                          # otherwise merge them (prefer the new values
        fn old_packet -> merge_packets(old_packet, packet) end)
      end
      )}
  end

  def handle_cast({:delete, packet}, state) do
    Logger.info("Deleting SSDP packet #{inspect(packet.nt)}")
    if is_nil(Map.get(state, packet.nt)) do
      Logger.debug("Not contained -> not deleting")
      {:noreply, state}
    else
      new_nt = Map.delete(Map.get(state, packet.nt), packet.usn)
      if map_size(new_nt) == 0 do
        Logger.debug("Deleting last entry for nt")
        {:noreply, Map.delete(state, packet.nt)}
      else
        Logger.debug("Deleting entry for nt")
        {:noreply, Map.put(state, packet.nt, new_nt)}
      end
    end
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  defp merge_packets(old_packet, new_packet) do
    Map.merge(old_packet, new_packet,
      fn _k, old_val, new_val ->
        if is_nil(new_val) do old_val else new_val end
      end)
  end
end
