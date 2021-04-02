defmodule Sise.Packet.Raw do
  # SPDX-License-Identifier: Apache-2.0

  defstruct [:location, :nt, :usn, :server,
    :boot_id, :config_id, :secure_location, :next_boot_id,
    :type, :host, :nts, :cache_control,
    :st,
    :man, :mx, :user_agent, :tcpport, :cpfn, :cpuuid]

end
