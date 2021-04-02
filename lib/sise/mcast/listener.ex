defmodule Sise.MCast.Listener do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

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
    ssdp_mcast = Sise.Config.multicast_addr()
    ssdp_port = Sise.Config.multicast_port()
    any = {0, 0, 0, 0}

    {:ok, socket} =
      :gen_udp.open(
        ssdp_port,
        [{:reuseaddr, true}, {:add_membership, {ssdp_mcast, any}}]
      )

    listen_to_udp(socket)
  end

  defp listen_to_udp(socket) do
    receive do
      {:udp, socket, _host, _port, msg} ->
        # forward the received packet but don't hand out the socket
        {:ok, _pid} =
          Task.Supervisor.start_child(
            Sise.MCast.ProcessorSupervisor,
            fn -> Sise.MCast.Processor.handle_msg(msg) end
          )

        # continue listening for packets
        listen_to_udp(socket)

      :stop ->
        :gen_udp.close(socket)
    end
  end
end
