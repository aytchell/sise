defmodule Ssdp.MCast.Listener do
# SPDX-License-Identifier: Apache-2.0

  def child_spec(_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link() do
    Task.start_link(fn -> open_and_listen() end)
  end

  defp open_and_listen() do
    ssdp_mcast = {239, 255, 255, 250}
    ssdp_port = 1900
    any = {0, 0, 0, 0}
    addmem_opt = {:add_membership, {ssdp_mcast, any}}
    {:ok, socket} = :gen_udp.open( ssdp_port, [{:reuseaddr, true}, addmem_opt])

    listen_to_udp(socket)
  end

  defp listen_to_udp(socket) do
    receive do
      {:udp, socket, _host, _port, msg} ->
        # forward the received packet but don't hand out the socket
        {:ok, _pid} = Task.Supervisor.start_child(
          Ssdp.MCast.ProcessorSupervisor,
          fn() -> Ssdp.MCast.Processor.handle_msg(msg) end)

        # continue listening for packets
        listen_to_udp(socket)
      :stop ->
        :gen_udp.close(socket)
    end
  end

end
