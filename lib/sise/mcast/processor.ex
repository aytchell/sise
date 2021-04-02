defmodule Sise.MCast.Processor do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  def handle_msg(msg) do
    packet = Sise.Packet.Parse.from_iolist(msg)

    case packet.type do
      :notify -> handle_notify(packet)
      :msearch -> nil
      _ -> nil
    end
  end

  def handle_notify(packet) do
    case packet.nts do
      "ssdp:alive" -> Sise.Cache.DeviceDb.add(packet)
      "ssdp:update" -> Sise.Cache.DeviceDb.update(packet)
      "ssdp:byebye" -> Sise.Cache.DeviceDb.delete(packet)
    end
  end
end
