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

  def subscribe(notification_type) do
    GenServer.cast(Ssdp.Cache.DeviceDb, {:sub, self(), notification_type})
  end

  def unsubscribe(notification_type) do
    GenServer.cast(Ssdp.Cache.DeviceDb, {:unsub, self(), notification_type})
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
    new_entries = add_or_update_packet(state.entries, packet)
    {:noreply, State.build(new_entries, state.listeners)}
  end

  def handle_cast({:update, packet}, state) do
    new_entries = add_or_update_packet(state.entries, packet)
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

  def handle_cast({:sub, pid, notification_type}, state) do
    Ssdp.Cache.Notifier.subscribe(pid, notification_type, state.entries)
    {:noreply, state}
  end

  def handle_cast({:unsub, pid, notification_type}, state) do
    Ssdp.Cache.Notifier.unsubscribe(pid, notification_type)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.entries, state}
  end

  defp add_or_update_packet(current_packets, new_packet) do
    nt_map = Map.get(current_packets, new_packet.nt)
    if is_nil(nt_map) do
      Logger.info("Added first entry for #{new_packet.nt}")
      Ssdp.Cache.Notifier.notify_add(new_packet)
      Map.put(current_packets, new_packet.nt,
        %{ new_packet.usn => new_packet })
    else
      if is_nil(Map.get(nt_map, new_packet.usn)) do
        Logger.info("Added new entry for #{new_packet.nt}")
        Ssdp.Cache.Notifier.notify_add(new_packet)
        Map.update!(current_packets, new_packet.nt,
          fn m -> Map.put(m, new_packet.usn, new_packet) end)
      else
        Logger.info("Updating entry for #{new_packet.nt}:#{new_packet.usn}")
        Map.update!(current_packets, new_packet.nt,
          fn m -> Map.update!(m, new_packet.usn,
            fn old -> update_entry(old, new_packet) end)
          end)
      end
    end
  end

  # Old and new packet have the same nt and same usn
  # check for differences, trigger notify and return new entry
  defp update_entry(old, new) do
    diff = Ssdp.Packet.diff(old, new)
    cond do
      is_empty(diff) -> old
      Ssdp.Packet.contains_location(diff) -> take_preferred(old, new)
      true ->
        Ssdp.Cache.Notifier.notify_update(new)
        new
    end
  end

  defp take_preferred(old_packet, new_packet) do
    old_is_local = Ssdp.Packet.is_localhost(old_packet)
    new_is_local = Ssdp.Packet.is_localhost(new_packet)
    merged = Ssdp.Packet.merge_packets(old_packet, new_packet)

    if Ssdp.Config.detect_prefers_localhost() do
      if old_is_local do
        if new_is_local do
          # both are localhost (preferred)
          Ssdp.Cache.Notifier.notify_update(merged)
          merged
        else
          # old is localhost (preferred); new isn't
          old_packet
        end
      else
        # old is not localhost (which would be preferred)
        Ssdp.Cache.Notifier.notify_update(merged)
        merged
      end
    else
      if old_is_local do
        # old is localhost (not preferred)
        Ssdp.Cache.Notifier.notify_update(merged)
        merged
      else
        if new_is_local do
          # new is localhost and old isn't (which is preferred)
          old_packet
        else
          # both are not localhost (preferred)
          Ssdp.Cache.Notifier.notify_update(merged)
          merged
        end
      end
    end
  end

  defp is_empty(list) do
    case list do
      [] -> true
      _ -> false
    end
  end

  defp delete_packet(current_packets, old_packet) do
    new_nt = Map.delete(Map.get(current_packets, old_packet.nt), old_packet.usn)
    if map_size(new_nt) == 0 do
      Map.delete(current_packets, old_packet.nt)
    else
      Map.put(current_packets, old_packet.nt, new_nt)
    end
  end
end