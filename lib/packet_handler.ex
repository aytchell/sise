defmodule SsdpClient.PacketHandler do

  import SsdpClient.SsdpPacket, only: [from_iolist: 1]

  def start_link() do
    Task.start_link(fn -> handle_packets() end)
  end

  def handle_packets() do
    receive do
      {:udp, _socket, _host, _port, msg} ->
        packet = from_iolist(msg)
    end
  end
end
