defmodule Ssdp.MCast.Processor do

  import SsdpClient.SsdpPacket, only: [from_iolist: 1]

  def handle_msg(msg) do
    packet = from_iolist(msg)
    case packet.type do
      :notify -> handle_notify(packet)
      :msearch -> handle_msearch(packet)
      otherwise -> IO.puts(otherwise)
    end
  end

  def handle_notify(packet) do
    case packet.nts do
      "ssdp:alive" -> Ssdp.DeviceDb.add(packet)
      "ssdp:update" -> Ssdp.DeviceDb.update(packet)
      "ssdp:byebye" -> Ssdp.DeviceDb.delete(packet)
    end
  end

  def handle_msearch(_packet) do
    IO.puts("msearch")
  end
end
