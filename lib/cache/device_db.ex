defmodule Ssdp.Cache.DeviceDb do
# SPDX-License-Identifier: Apache-2.0

  use GenServer
  require Logger

  def child_spec() do
    %{
      id: Ssdp.Cache.DeviceDb,
      name: Ssdp.Cache.DeviceDb,
      start: {Ssdp.Cache.DeviceDb, :start_link, %{}}
    }
  end

  defmodule State do
    @enforce_keys [:entries, :listeners]
    defstruct [:entries, :listeners]

    def empty() do
      %State{entries: %{}, listeners: []}
    end

    def build(entries, listeners) do
      %State{entries: entries, listeners: listeners}
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, Ssdp.Cache.DeviceDb.State.empty(), opts)
  end

  def get_all() do
    GenServer.call(Ssdp.Cache.DeviceDb, :get)
  end

  def add(packet) do
    cast_if_nt_and_usn(packet, :add)
  end

  def update(packet) do
    cast_if_nt_and_usn(packet, :update)
  end

  def delete(packet) do
    cast_if_nt_and_usn(packet, :delete)
  end

  defp cast_if_nt_and_usn(packet, command) do
    if Map.has_key?(packet, :nt) do
      if Map.has_key?(packet, :usn) do
        GenServer.cast(Ssdp.Cache.DeviceDb, {command, packet})
      else
        cmd = Atom.to_string(command)
        Logger.warn("Won't #{cmd} SSDP packet since it's missing 'USN'")
      end
    else
      cmd = Atom.to_string(command)
      Logger.warn("Won't #{cmd} SSDP packet since it's missing 'NT'")
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:add, packet}, state) do
    Logger.info("Adding SSDP packet #{inspect(packet.nt)}")
    new_entries = add_packet(state.entries, packet)
    Ssdp.Cache.Notifier.notify_add(packet)
    {:noreply, State.build(new_entries, state.listeners)}
  end

  def handle_cast({:update, packet}, state) do
    Logger.info("Updating SSDP packet #{inspect(packet.nt)}")
    new_entries = update_packet(state.entries, packet)
    Ssdp.Cache.Notifier.notify_update(packet)
    {:noreply, State.build(new_entries, state.listeners)}
  end

  def handle_cast({:delete, packet}, state) do
    if is_nil(Map.get(state, packet.nt)) do
      {:noreply, state}
    else
      Logger.info("Deleting SSDP packet #{inspect(packet.nt)}")
      Ssdp.Cache.Notifier.notify_delete(packet)
      new_entries = delete_packet(state.entries, packet)
      {:noreply, State.build(new_entries, state.listeners)}
    end
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.entries, state}
  end

  defp add_packet(current_packets, new_packet) do
    Map.update(
      current_packets,                    # current state (to be updated)
      new_packet.nt,                      # key (device- or service-type)
      %{ new_packet.usn => new_packet },  # in case there's no such entry
      fn old_state -> Map.update(   # if there's already a map for this nt
        old_state,        # old nt-map (to be updated)
        new_packet.usn,   # key (unique id of this device/service)
        new_packet,       # in case this usn is not yet present
        fn _old_packet -> new_packet end) # otherwise we simply replace it
      end
    )
  end

  defp update_packet(current_packets, new_packet) do
    Map.update(
      current_packets,                    # current state (to be updated)
      new_packet.nt,                      # key (device- or service-type)
      %{ new_packet.usn => new_packet },  # in case there's no such entry
      fn old_state -> Map.update(   # if there's already a map for this nt
        old_state,        # old nt-map (to be updated)
        new_packet.usn,   # key (unique id of this device/service)
        new_packet,       # in case this usn is not yet present
                          # otherwise merge them (prefer the new values
        fn old_packet -> merge_packets(old_packet, new_packet) end)
      end
    )
  end

  defp delete_packet(current_packets, old_packet) do
    new_nt = Map.delete(Map.get(current_packets, old_packet.nt), old_packet.usn)
    if map_size(new_nt) == 0 do
      Map.delete(current_packets, old_packet.nt)
    else
      Map.put(current_packets, old_packet.nt, new_nt)
    end
  end

  defp merge_packets(old_packet, new_packet) do
    Map.merge(old_packet, new_packet,
      fn _k, old_val, new_val ->
        if is_nil(new_val) do old_val else new_val end
      end)
  end
end
