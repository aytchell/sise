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
    GenServer.start_link(__MODULE__, Sise.Cache.Entries.empty(), opts)
  end

  def get(notification_type) do
    GenServer.call(Sise.Cache.DeviceDb, {:get, notification_type})
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
    new_entries = handle_add_or_update(entries, discovery)
    {:noreply, new_entries}
  end

  def handle_cast({:update, discovery}, entries) do
    new_entries = handle_add_or_update(entries, discovery)
    {:noreply, new_entries}
  end

  def handle_cast({:delete, discovery}, entries) do
    new_entries = handle_delete(entries, discovery)
    {:noreply, new_entries}
  end

  def handle_cast({:sub, pid, notification_type}, entries) do
    Sise.Cache.Notifier.subscribe(pid, notification_type,
      Sise.Cache.Entries.as_list(entries, notification_type))
    {:noreply, entries}
  end

  def handle_cast({:unsub, pid, notification_type}, entries) do
    Sise.Cache.Notifier.unsubscribe(pid, notification_type)
    {:noreply, entries}
  end

  @impl true
  def handle_call({:get, notification_type}, _from, entries) do
    {:reply, Sise.Cache.Entries.as_list(entries, notification_type), entries}
  end

  defp handle_add_or_update(entries, discovery) do
    case Sise.Cache.Entries.add_or_update(entries, discovery) do
      :noop ->
        Logger.debug("Discovered entry is already known")
        entries
      {:add, new_entries} ->
        Logger.info("Added new entry for #{discovery.nt}")
        Sise.Cache.Notifier.notify_add(discovery)
        new_entries
      {:update, new_entries, diff} ->
        Logger.info("Updating entry for #{discovery.nt}:#{discovery.usn}")
        Sise.Cache.Notifier.notify_update(discovery, diff)
        new_entries
    end
  end

  defp handle_delete(entries, discovery) do
    case Sise.Cache.Entries.delete(entries, discovery) do
      :noop ->
        Logger.debug("Deleted entry is already gone")
        entries
      {:delete, del_entry, new_entries} ->
        Logger.info("Deleting SSDP packet #{inspect(discovery.nt)}")
        Sise.Cache.Notifier.notify_delete(del_entry)
        new_entries
    end
  end
end
