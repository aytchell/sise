defmodule Sise.Cache.DeviceDb do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  use GenServer
  require Logger

  def child_spec() do
    %{
      id: Sise.Cache.DeviceDb,
      name: Sise.Cache.DeviceDb,
      start: {Sise.Cache.DeviceDb, :start_link, %{}}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def get_all() do
    GenServer.call(Sise.Cache.DeviceDb, :get)
  end

  def subscribe(notification_type) do
    GenServer.cast(Sise.Cache.DeviceDb, {:sub, self(), notification_type})
  end

  def unsubscribe(notification_type) do
    GenServer.cast(Sise.Cache.DeviceDb, {:unsub, self(), notification_type})
  end

  def add(raw_packet) do
    cast_if_nt_and_usn(raw_packet, :add)
  end

  def update(raw_packet) do
    cast_if_nt_and_usn(raw_packet, :update)
  end

  def delete(raw_packet) do
    cast_if_nt_and_usn(raw_packet, :delete)
  end

  defp cast_if_nt_and_usn(raw_packet, command) do
    if Map.has_key?(raw_packet, :nt) do
      if Map.has_key?(raw_packet, :usn) do
        discovery = Sise.Packet.Raw.to_discovery(raw_packet)
        GenServer.cast(Sise.Cache.DeviceDb, {command, discovery})
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
  def init(entries) do
    {:ok, entries}
  end

  @impl true
  def handle_cast({:add, discovery}, entries) do
    new_entries = add_or_update_discovery(entries, discovery)
    {:noreply, new_entries}
  end

  def handle_cast({:update, discovery}, entries) do
    new_entries = add_or_update_discovery(entries, discovery)
    {:noreply, new_entries}
  end

  def handle_cast({:delete, discovery}, entries) do
    nt_map = Map.get(entries, discovery.nt)

    if is_nil(nt_map) do
      {:noreply, entries}
    else
      entry = Map.get(nt_map, discovery.usn)

      if is_nil(entry) do
        {:noreply, entries}
      else
        Logger.info("Deleting SSDP packet #{inspect(entry.nt)}")
        Sise.Cache.Notifier.notify_delete(entry)
        new_entries = delete_packet(entries, entry)
        {:noreply, new_entries}
      end
    end
  end

  def handle_cast({:sub, pid, notification_type}, entries) do
    Sise.Cache.Notifier.subscribe(pid, notification_type, flatten_entries(entries))
    {:noreply, entries}
  end

  def handle_cast({:unsub, pid, notification_type}, entries) do
    Sise.Cache.Notifier.unsubscribe(pid, notification_type)
    {:noreply, entries}
  end

  @impl true
  def handle_call(:get, _from, entries) do
    {:reply, flatten_entries(entries), entries}
  end

  defp add_or_update_discovery(current_packets, new_discovery) do
    nt_map = Map.get(current_packets, new_discovery.nt)

    if is_nil(nt_map) do
      Logger.info("Added first entry for #{new_discovery.nt}")
      Sise.Cache.Notifier.notify_add(new_discovery)
      Map.put(current_packets, new_discovery.nt, %{new_discovery.usn => new_discovery})
    else
      if is_nil(Map.get(nt_map, new_discovery.usn)) do
        Logger.info("Added new entry for #{new_discovery.nt}")
        Sise.Cache.Notifier.notify_add(new_discovery)

        Map.update!(current_packets, new_discovery.nt, fn m ->
          Map.put(m, new_discovery.usn, new_discovery)
        end)
      else
        Logger.info("Updating entry for #{new_discovery.nt}:#{new_discovery.usn}")

        Map.update!(current_packets, new_discovery.nt, fn m ->
          Map.update!(m, new_discovery.usn, fn old -> update_entry(old, new_discovery) end)
        end)
      end
    end
  end

  # Old and new packet have the same nt and same usn
  # check for differences, trigger notify and return new entry
  defp update_entry(old, new) do
    diff = Sise.Packet.diff(old, new)

    cond do
      Enum.empty?(diff) ->
        old

      Sise.Packet.contains_location(diff) ->
        take_preferred(old, new)

      true ->
        Sise.Cache.Notifier.notify_update(new)
        new
    end
  end

  defp take_preferred(old_packet, new_packet) do
    old_is_local = Sise.Packet.is_localhost(old_packet)
    new_is_local = Sise.Packet.is_localhost(new_packet)
    pref_local = Sise.Config.detect_prefers_localhost()

    merged = Sise.Packet.merge_packets(old_packet, new_packet)

    if pref_local == old_is_local && pref_local != new_is_local do
      # if the old packet fits the preference but the new one doesn't
      # then we keep the old entry
      old_packet
    else
      # in all other cases we take the new entry (but fill in missing values
      # with the old entry's values)
      Sise.Cache.Notifier.notify_update(merged)
      merged
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

  # our stored ssdp entries are organized as Map<:nt, Map<:usn, packet>>.
  # This function flattend this structure so that we get a List<packet>
  # which is required when we'd like to inform a new listener
  defp flatten_entries(entries) do
    Enum.flat_map(Map.values(entries), fn x -> Map.values(x) end)
  end
end
