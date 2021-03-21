defmodule Ssdp.MCast.Processor do

  import SsdpClient.SsdpPacket, only: [from_iolist: 1]

  def handle_msg(msg) do
    IO.puts("decoding packet")
    packet = from_iolist(msg)
    IO.puts("packet decoded")
    Ssdp.DeviceDb.add(packet)
  end
end
