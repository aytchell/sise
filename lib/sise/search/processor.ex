defmodule Sise.Search.Processor do
  # SPDX-License-Identifier: Apache-2.0

  def handle_msg(msg) do
    packet = Sise.Packet.from_iolist(msg)
    Sise.Cache.DeviceDb.add(packet)
  end
end
