defmodule Ssdp.Search.Broadcaster do
# SPDX-License-Identifier: Apache-2.0

  require Logger

  defmodule State do
    defstruct [ :socket, :timer_ref, :attempts_left ]
  end

  use GenServer

  @multicast_addr {239, 255, 255, 250}
  @multicast_port 1900

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
    send_msearch_message(state.socket)

    if state.attempts_left <= 1 do
      # This was the last attempt.
      timeout_msec = (Ssdp.Config.msearch_max_seconds() + 1) * 1000
      Process.send_after(self(), :timeout, timeout_msec)

      {:noreply, %State{state |
        timer_ref: Process.send_after(self(), :ok,
          Ssdp.Config.msearch_repeat_interval_msec())}}
    else
      {:noreply, %State{socket: state.socket,
        attempts_left: state.attempts_left - 1,
        timer_ref: Process.send_after(self(), :ok, 1000)}}
    end
  end

  defp open_unicast_socket() do
    :gen_udp.open(0, [
      {:reuseaddr, true},
      {:multicast_ttl, Ssdp.Config.msearch_ttl()},
      {:multicast_loop, Ssdp.Config.msearch_find_locals()}
    ])
  end

  defp send_msearch_message(socket) do
    message = build_search_msg(
      Ssdp.Config.msearch_search_target(),
      Ssdp.Config.msearch_max_seconds())
    :gen_udp.send(socket, @multicast_addr, @multicast_port, message)
  end

  defp build_search_msg(search_target, max_seconds) do
    "M-SEARCH * HTTP/1.1\r\n" <>
    "Host: #{:inet_parse.ntoa(@multicast_addr)}:#{@multicast_port}\r\n" <>
    "MAN: \"ssdp:discover\"\r\n" <>
    "ST: #{search_target}\r\n" <>
    "MX: #{max_seconds}\r\n\r\n"
  end

  def close_socket(state) do
    unless is_nil(state.socket) do
      :gen_udp.close(state.socket)
    end
  end
end
