defmodule Ssdp.Search.Processor do
  #SPDX-License-Identifier: Apache-2.0

  import Ssdp.SsdpPacket, only: [from_iolist: 1]

  def handle_msg(msg) do
    packet = from_iolist(msg)
    Ssdp.DeviceDb.add(packet)
  end
end
