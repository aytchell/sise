defmodule Sise.Packet.Notify do
  # SPDX-License-Identifier: Apache-2.0

  require Logger

  @doc """
  Compares two ssdp packets
  Returns :eq if they are equal, :neq otherwise
  """
  def compare(packet_1, packet_2) do
    if packet_1.type != packet_2.type do
      :neq
    else
      values = zip_packets_to_valuetuple_list(packet_1, packet_2)

      if all_valuetuples_equals(values) do
        Logger.info("compare packet -> true")
          :eq
      else
        Logger.info("compare packet -> false")
          :neq
      end
    end
  end

  @doc """
  Finds the keys of two ssdp packets whose values differ
  Returns the list of differing keys
  """
  def diff(packet_1, packet_2) do
    key_value_tuples = zip_packets_to_keyvaluetuple_list(packet_1, packet_2)

    Enum.reduce(key_value_tuples, [], fn {k1, v1, v2}, acc ->
      if v1 == v2 do
        acc
      else
        [k1 | acc]
      end
    end)
  end

  def contains_location(diff) do
    case diff do
      [] -> false
      [:location | _tail] -> true
      [_head | tail] -> contains_location(tail)
    end
  end

  def is_localhost(packet) do
    pattern = :binary.compile_pattern(["://localhost:", "://localhost/", "://127."])

    cond do
      is_nil(packet.location) -> false
      String.contains?(packet.location, pattern) -> true
      true -> false
    end
  end

  defp zip_packets_to_valuetuple_list(packet_1, packet_2) do
    Enum.map(
      Enum.to_list(
        Stream.zip(
          Map.from_struct(packet_1),
          Map.from_struct(packet_2)
        )
      ),
      fn {{_k1, v1}, {_k2, v2}} -> {v1, v2} end
    )
  end

  defp zip_packets_to_keyvaluetuple_list(packet_1, packet_2) do
    Enum.map(
      Enum.to_list(
        Stream.zip(
          Map.from_struct(packet_1),
          Map.from_struct(packet_2)
        )
      ),
      fn {{k1, v1}, {_k2, v2}} -> {k1, v1, v2} end
    )
  end

  defp all_valuetuples_equals(list) do
    Enum.reduce(list, true, fn {v1, v2}, acc -> acc && values_equal(v1, v2) end)
  end

  defp values_equal(v1, v2) do
    if v1 == v2 do
      true
    else
      Logger.info("Values differ: #{v1} != #{v2}")
      false
    end
  end
end
