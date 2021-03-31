defmodule Ssdp.Cache.Notifier do
# SPDX-License-Identifier: Apache-2.0

  use GenServer
  require Logger

  def child_spec() do
    %{
      id: Ssdp.Cache.Notifier,
      name: Ssdp.Cache.Notifier,
      start: {Ssdp.Cache.Notifier, :start_link, []}
    }
  end

  defmodule Subscriber do
    @enforce_keys [:pid, :type, :monitor_ref]
    defstruct [:pid, :type, :monitor_ref]

    def build(pid, type, ref) do
      %Subscriber{pid: pid, type: type, monitor_ref: ref}
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def subscribe(pid, type, packets) do
    GenServer.cast(Ssdp.Cache.Notifier, {:sub, pid, type, packets})
  end

  def unsubscribe(pid, type) do
    GenServer.cast(Ssdp.Cache.Notifier, {:unsub, pid, type})
  end

  def notify_add(packet) do
    GenServer.cast(Ssdp.Cache.Notifier, {:notify_add, packet})
  end

  def notify_update(packet) do
    GenServer.cast(Ssdp.Cache.Notifier, {:notify_update, packet})
  end

  def notify_delete(packet) do
    GenServer.cast(Ssdp.Cache.Notifier, {:notify_delete, packet})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:sub, pid, type, packets}, state) do
    ref = Process.monitor(pid)
    listener = Subscriber.build(pid, type, ref)
    Enum.each(packets, fn p -> notify_listener(p, :ssdp_add, listener) end)
    {:noreply, [listener | state]}
  end

  def handle_cast({:unsub, pid, type}, state) do
    Logger.debug("Ssdp-Listener unsubscribed; will no longer notify it")
    {:noreply, delete_listener(state, pid, type, [])}
  end

  def handle_cast({:notify_add, packet}, state) do
    notify(packet, :ssdp_add, state)
    {:noreply, state}
  end

  def handle_cast({:notify_update, packet}, state) do
    notify(packet, :ssdp_update, state)
    {:noreply, state}
  end

  def handle_cast({:notify_delete, packet}, state) do
    notify(packet, :ssdp_delete, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _object, _reason}, state) do
    Logger.debug("Ssdp-Listener died; will no longer notify it")
    {:noreply, Enum.filter(state, fn sub -> sub.monitor_ref != ref end)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp notify(packet, what, listeners) do
    case listeners do
      [] -> nil
      [head | tail] ->
        notify_listener(packet, what, head)
        notify(packet, what, tail)
    end
  end

  defp notify_listener(packet, what, listener) do
    cond do
      listener.type == "all" -> send(listener.pid, {what, packet})
      listener.type == packet.nt -> send(listener.pid, {what, packet})
      true -> nil
    end
  end

  defp delete_listener(listeners, pid, type, acc) do
    case listeners do
      [] -> acc
      [head | tail] ->
        cond do
          head.pid != pid -> delete_listener(tail, pid, type, [head | acc])
          true ->
            if type == "all" || type == head.type do
              Process.demonitor(head.monitor_ref)
              delete_listener(tail, pid, type, acc)
            else
              delete_listener(tail, pid, type, [head | acc])
            end
        end
    end
  end
end
