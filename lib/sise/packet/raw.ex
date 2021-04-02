defmodule Sise.Packet.Raw do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  defstruct [:location, :nt, :usn, :server,
    :boot_id, :config_id, :secure_location, :next_boot_id,
    :type, :host, :nts, :cache_control,
    :st,
    :man, :mx, :user_agent, :tcpport, :cpfn, :cpuuid]

  def to_discovery(raw) do
    discovery = %Sise.Discovery{
      location: raw.location, nt: raw.nt, usn: raw.usn}
    copy_optional_raw(discovery, Map.to_list(Map.from_struct(raw)))
  end

  defp copy_optional_raw(discovery, optionals) do
    case optionals do
      [] -> discovery
      [entry|tail] ->
        case entry do
          {_, nil} -> copy_optional_raw(discovery, tail)
          {:server, value} ->
            copy_optional_raw(%{discovery|server: value}, tail)
          {:boot_id, value} ->
            copy_optional_raw(%{discovery|boot_id: value}, tail)
          {:config_id, value} ->
            copy_optional_raw(%{discovery|config_id: value}, tail)
          {:secure_location, value} ->
            copy_optional_raw(%{discovery|secure_location: value}, tail)
          {:next_boot_id, value} ->
            copy_optional_raw(%{discovery|next_boot_id: value}, tail)
          _ -> copy_optional_raw(discovery, tail)
        end
    end
  end
end
