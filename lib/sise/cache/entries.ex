defmodule Sise.Cache.Entries do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  require Logger
  alias Sise.Discovery

  def empty() do
    %{}
  end

  def as_list(entries, :all) do
    Enum.flat_map(Map.values(entries), fn x -> Map.values(x) end)
  end

  def as_list(entries, notification_type) do
    case Map.get(entries, notification_type) do
      nil -> []
      nt_map -> Map.values(nt_map)
    end
  end

  def get_entry(entries, nt, usn) do
    nt_map = Map.get(entries, nt)

    if is_nil(nt_map) do
      nil
    else
      Map.get(nt_map, usn)
    end
  end

  def add_or_update(entries, discovery) do
    case get_entry(entries, discovery.nt, discovery.usn) do
      nil -> {:add, insert_discovery(entries, discovery)}
      old_entry -> update_if_needed(entries, old_entry, discovery)
    end
  end

  def delete(entries, discovery) do
    case get_entry(entries, discovery.nt, discovery.usn) do
      nil -> :noop
      old_entry -> {:delete, old_entry, delete_discovery(entries, old_entry)}
    end
  end

  defp update_if_needed(entries, old_entry, discovery) do
    if prefer_old(old_entry, discovery) do
      :noop
    else
      diff = Discovery.diff(old_entry, discovery)
      if Enum.empty?(diff) do
        :noop
      else
        {:update,
          insert_discovery(entries, Discovery.merge(old_entry, discovery)),
          diff}
      end
    end
  end

  defp insert_discovery(entries, discovery) do
    Map.update(
      entries,
      discovery.nt,
      %{discovery.usn => discovery},
      fn nt_map -> Map.put(nt_map, discovery.usn, discovery) end)
  end

  defp prefer_old(old_entry, discovery) do
    old_is_local = Sise.Discovery.localhost?(old_entry)
    new_is_local = Sise.Discovery.localhost?(discovery)
    pref_local = Sise.Config.detect_prefers_localhost()

    old_is_local == pref_local && new_is_local != pref_local
  end

  defp delete_discovery(entries, old_entry) do
    if map_size(Map.get(entries, old_entry.nt)) == 1 do
      Map.delete(entries, old_entry.nt)
    else
      Map.update!(entries, old_entry.nt,
        fn nt_map -> Map.delete(nt_map, old_entry.usn) end)
    end
  end
end
