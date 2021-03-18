defmodule SsdpClient do
  @moduledoc """
  An SSDP Client
  """

  import SsdpClient.SsdpPacket, only: [from_iolist: 1]

  def start_link() do
    Task.start_link(fn -> open_and_listen() end)
  end

  defp open_and_listen() do
    ssdp_mcast = {239, 255, 255, 250}
    ssdp_port = 1900
    any = {0, 0, 0, 0}
    addmem_opt = {:add_membership, {ssdp_mcast, any}}
    {:ok, socket} = :gen_udp.open( ssdp_port, [{:reuseaddr, true}, addmem_opt])
    IO.puts("opened socket")

    listen_to_udp(socket)
  end

  defp listen_to_udp(socket) do
    IO.puts("listening...")
    receive do
      {:udp, socket, _host, _port, msg} ->
        packet = from_iolist(msg)
        IO.puts("received udp: " + packet)
        listen_to_udp(socket)
      :close ->
        :gen_udp.close(socket)
        IO.puts("exiting")
    end
  end
end
