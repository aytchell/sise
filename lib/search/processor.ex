defmodule Ssdp.Search.Processor do
  #SPDX-License-Identifier: Apache-2.0

  def handle_msg(msg) do
    packet = Ssdp.Packet.from_iolist(msg)
    Ssdp.Cache.DeviceDb.add(packet)
  end
end
