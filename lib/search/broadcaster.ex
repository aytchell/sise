defmodule Ssdp.Search.Broadcaster do
# SPDX-License-Identifier: Apache-2.0

  require Logger

  defmodule State do
    defstruct [ :socket, :timer_ref, :attempts_left ]
  end

  # Repeat M-SEARCH every 20 minutes
  @twenty_minutes 20 * 60 * 1000

  # UPnP/SSDP spec says:
  # "The TTL for the IP packet should default to 2 and should be configurable"
  @msearch_ttl 2

  use GenServer

  def child_spec() do
    %{
      id: __MODULE__,
      name: Ssdp.Search.Broadcaster,
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link(opts) do
    {:ok, pid} = GenServer.start_link(__MODULE__, %State{}, opts)
    GenServer.cast(pid, :ok)
    {:ok, pid}
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:ok, state) do
    if is_nil(state.socket) do
      Logger.info("Sending out M-Search messages")
      handle_first_msg()
    else
      handle_follow_up_msg(state)
    end
  end

  @impl true
  def handle_info(:ok, state) do
    GenServer.cast(self(), :ok)
    {:noreply, %State{state | timer_ref: nil}}
  end

  def handle_info({:udp, _socket, _host, _port, msg}, state) do
    {:ok, _pid} = Task.Supervisor.start_child(
      Ssdp.Search.ProcessorSupervisor,
      fn() -> Ssdp.Search.Processor.handle_msg(msg) end)
    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    Logger.info("Finished M-Search. Going to sleep")
    close_socket(state)
    {:noreply, %State{state | socket: nil}}
  end

  @impl true
  def terminate(_reason, state) do
    unless is_nil(state.timer_ref) do
      Process.cancel_timer(state.timer_ref)
    end
    close_socket(state)
    # the return value is ignored
  end

  # Open the socket and send the first M-SEARCH message
  defp handle_first_msg() do
    {:ok, socket} = open_unicast_socket()
    send_msearch_message(socket)
    {:noreply, %State{socket: socket, attempts_left: 2,
      timer_ref: Process.send_after(self(), :ok, 1000)}}
  end

  # Send some more M-SEARCH messages in case the first message got lost
  defp handle_follow_up_msg(state) do
    if state.attempts_left == 0 do
      # We're done. Wait some seconds for answers, then close the socket
      Process.send_after(self(), :timeout, 6000)
      {:noreply, %State{state |
        timer_ref: Process.send_after(self(), :ok, @twenty_minutes)}}
    else
      send_msearch_message(state.socket)
      {:noreply, %State{socket: state.socket,
        attempts_left: state.attempts_left - 1,
        timer_ref: Process.send_after(self(), :ok, 1000)}}
    end
  end

  defp open_unicast_socket() do
    :gen_udp.open(0, [{:reuseaddr, true}, {:multicast_ttl, @msearch_ttl}])
  end

  defp send_msearch_message(socket) do
    message = build_search_msg("ssdp:all")
    :gen_udp.send(socket, {239, 255, 255, 250}, 1900, message)
  end

  defp build_search_msg(search_target) do
    "M-SEARCH * HTTP/1.1\r\n" <>
      "Host: 239.255.255.250:1900\r\n" <>
        "MAN: \"ssdp:discover\"\r\n" <>
          "ST: #{search_target}\r\n" <>
            "MX: 5\r\n\r\n"
  end

  def close_socket(state) do
    unless is_nil(state.socket) do
      :gen_udp.close(state.socket)
    end
  end
end
