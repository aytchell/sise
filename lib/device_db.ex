defmodule Ssdp.DeviceDb do
# SPDX-License-Identifier: Apache-2.0

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
        GenServer.cast(Ssdp.DeviceDb, {command, packet})
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
    if is_nil(Map.get(state, packet.nt)) do
      {:noreply, state}
    else
      Logger.info("Deleting SSDP packet #{inspect(packet.nt)}")
      new_nt = Map.delete(Map.get(state, packet.nt), packet.usn)
      if map_size(new_nt) == 0 do
        {:noreply, Map.delete(state, packet.nt)}
      else
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
