defmodule Sise.Search.Processor do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  def handle_msg(msg) do
    packet = Sise.Packet.Parse.from_iolist(msg)
    Sise.Cache.DeviceDb.add(packet)
  end
end
