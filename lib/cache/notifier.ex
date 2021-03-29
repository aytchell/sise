defmodule Ssdp.Cache.Notifier do
# SPDX-License-Identifier: Apache-2.0

  use GenServer

  def child_spec() do
    %{
      id: Ssdp.Cache.Notifier,
      name: Ssdp.Cache.Notifier,
      start: {Ssdp.Cache.Notifier, :start_link, []}
    }
  end

  defmodule Subscriber do
    @enforce_keys [:pid, :type]
    defstruct [:pid, :type]

    def build(pid, type) do
      %Subscriber{pid: pid, type: type}
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def subscribe(type) do
    GenServer.cast(Ssdp.Cache.Notifier, {:subscribe, self(), type})
  end

  def subscribe_all() do
    subscribe("all")
  end

  def unsubscribe(type) do
    GenServer.cast(Ssdp.Cache.Notifier, {:unsubscribe, self(), type})
  end

  def unsubscribe_all() do
    unsubscribe("all")
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
  def handle_cast({:subscribe, pid, type}, state) do
    {:noreply, [Subscriber.build(pid, type) | state]}
  end

  def handle_cast({:unsubscribe, pid, type}, state) do
    case type do
      "all" -> {:noreply, Enum.filter(state, fn sub -> sub.pid != pid end)}
      _ -> {:noreply, List.delete(state, Subscriber.build(pid, type))}
    end
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
end
