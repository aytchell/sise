defmodule Sise.Discovery do
  # SPDX-License-Identifier: Apache-2.0

  @enforce_keys [:location, :nt, :usn]
  defstruct [:location, :nt, :usn, :server,
    :boot_id, :config_id, :secure_location, :next_boot_id]

  @doc """
  Merge two discovery packets
  One packet provides the "base values" the other one provides "updates"
  on top of the base. If for any key there's no "updated" value then
  the base value is used.
  """
  def merge(base, on_top) do
    Map.merge(base, on_top, fn _k, base_val, on_top_val ->
      if is_nil(on_top_val) do
        base_val
      else
        on_top_val
      end
    end)
  end
end
