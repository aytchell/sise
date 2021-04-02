defmodule Sise.Packet.MSearch do
  # SPDX-License-Identifier: Apache-2.0

  defstruct [:type,
    :host,
    :man, :mx, :st, :user_agent, :tcpport, :cpfn, :cpuuid]

end
