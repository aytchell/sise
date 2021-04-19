defmodule Sise.Cache.Notifier do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  use GenServer
  require Logger

  def child_spec() do
    %{
      id: Sise.Cache.Notifier,
      name: Sise.Cache.Notifier,
      start: {Sise.Cache.Notifier, :start_link, []}
    }
  end

  defmodule Observer do
    @moduledoc false

    @enforce_keys [:pid, :type, :monitor_ref]
    defstruct [:pid, :type, :monitor_ref]

    def build(pid, type, ref) do
      %Observer{pid: pid, type: type, monitor_ref: ref}
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def subscribe(pid, type, packet_list) do
    GenServer.cast(Sise.Cache.Notifier, {:sub, pid, type, packet_list})
  end

  def unsubscribe(pid, type) do
    GenServer.cast(Sise.Cache.Notifier, {:unsub, pid, type})
  end

  def notify_add(packet) do
    GenServer.cast(Sise.Cache.Notifier, {:notify_add, packet})
  end

  def notify_update(packet, diff) do
    GenServer.cast(Sise.Cache.Notifier, {:notify_update, packet, diff})
  end

  def notify_delete(packet) do
    GenServer.cast(Sise.Cache.Notifier, {:notify_delete, packet})
  end

  @impl true
  def init(observer_list) do
    {:ok, observer_list}
  end

  @impl true
  def handle_cast({:sub, pid, type, packet_list}, observer_list) do
    ref = Process.monitor(pid)
    obs = Observer.build(pid, type, ref)

    Enum.each(packet_list, fn pkg ->
      notify_observer(
        obs,
        pkg.nt,
        {:ssdp_add, pkg}
      )
    end)

    {:noreply, [obs | observer_list]}
  end

  def handle_cast({:unsub, pid, type}, observer_list) do
    Logger.debug("Ssdp-Listener unsubscribed; will no longer notify it")
    {:noreply, delete_observer(observer_list, pid, type, [])}
  end

  def handle_cast({:notify_add, packet}, observer_list) do
    notify_observer_list(packet.nt, observer_list, {:ssdp_add, packet})
    {:noreply, observer_list}
  end

  def handle_cast({:notify_update, packet, diff}, observer_list) do
    notify_observer_list(packet.nt, observer_list, {:ssdp_update, packet, diff})
    {:noreply, observer_list}
  end

  def handle_cast({:notify_delete, packet}, observer_list) do
    notify_observer_list(packet.nt, observer_list, {:ssdp_delete, packet})
    {:noreply, observer_list}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _object, _reason}, observer_list) do
    Logger.debug("Ssdp-Listener died; will no longer notify it")
    {:noreply, Enum.filter(observer_list, fn sub -> sub.monitor_ref != ref end)}
  end

  def handle_info(_, observer_list) do
    {:noreply, observer_list}
  end

  defp notify_observer_list(nt, observer_list, notification) do
    Enum.each(
      observer_list,
      fn obs -> notify_observer(obs, nt, notification) end
    )
  end

  defp notify_observer(obs, nt, notification) do
    cond do
      obs.type == :all -> send(obs.pid, notification)
      obs.type == nt -> send(obs.pid, notification)
      true -> nil
    end
  end

  defp delete_observer(observer_list, pid, type, acc) do
    case observer_list do
      [] ->
        acc

      [head | tail] ->
        cond do
          head.pid != pid ->
            delete_observer(tail, pid, type, [head | acc])

          true ->
            if type == :all || type == head.type do
              Process.demonitor(head.monitor_ref)
              delete_observer(tail, pid, type, acc)
            else
              delete_observer(tail, pid, type, [head | acc])
            end
        end
    end
  end
end
