defmodule Sise.MCast.Processor do
  # SPDX-License-Identifier: Apache-2.0

  def handle_msg(msg) do
    packet = Sise.Packet.from_iolist(msg)

    case packet.type do
      :notify -> handle_notify(packet)
      :msearch -> handle_msearch(packet)
      otherwise -> IO.puts(otherwise)
    end
  end

  def handle_notify(packet) do
    case packet.nts do
      "ssdp:alive" -> Sise.Cache.DeviceDb.add(packet)
      "ssdp:update" -> Sise.Cache.DeviceDb.update(packet)
      "ssdp:byebye" -> Sise.Cache.DeviceDb.delete(packet)
    end
  end

  def handle_msearch(_packet) do
    # Answering to M-SEARCH is not supported
    IO.puts("msearch")
  end
end