defmodule Ssdp.Packet do
# SPDX-License-Identifier: Apache-2.0

  require Logger

  defmodule Utils do
    def split_http_header(header) do
      [name | [content]] = String.split(header, ":", parts: 2)
      fn(x) -> String.trim(x) end
      {
        String.downcase(String.trim(name), :ascii),
        String.trim(content)
      }
    end
  end

  @doc """
  Merge two packets
  One packet provides the "base values" the other one provides "updates"
  on top of the base. If for any key there's no "updated" value then
  the base value is used.
  """
  def merge_packets(base, on_top) do
    Map.merge(base, on_top,
      fn _k, base_val, on_top_val ->
        if is_nil(on_top_val) do base_val else on_top_val end
      end)
  end

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
    Enum.reduce(key_value_tuples, [],
      fn {k1, v1, v2}, acc ->
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
      [:location|_tail] -> true
      [_head|tail] -> contains_location(tail)
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
      Enum.to_list(Stream.zip(
        Map.from_struct(packet_1),
        Map.from_struct(packet_2)
      )),
      fn {{_k1, v1}, {_k2, v2}} -> {v1, v2} end)
  end

  defp zip_packets_to_keyvaluetuple_list(packet_1, packet_2) do
    Enum.map(
      Enum.to_list(Stream.zip(
        Map.from_struct(packet_1),
        Map.from_struct(packet_2)
      )),
      fn {{k1, v1}, {_k2, v2}} -> {k1, v1, v2} end)
  end

  defp all_valuetuples_equals(list) do
    Enum.reduce(list, true,
      fn {v1, v2}, acc -> acc && values_equal(v1, v2) end)
  end

  defp values_equal(v1, v2) do
    if v1 == v2 do
      true
    else
      Logger.info("Values differ: #{v1} != #{v2}")
      false
    end
  end

  defmodule Notify do
    alias Ssdp.Packet.Utils

    defstruct [ :type, :location, :nt, :nts, :server, :usn, :host, :cache_control ]

    def parse(headers) do
      parse_accumulate(headers, %Ssdp.Packet.Notify{type: :notify})
    end

    defp parse_accumulate(headers, packet) do
      case headers do
        [] -> packet
        [head | tail] -> parse_accumulate(tail, add_entry(packet, head))
      end
    end

    defp add_entry(packet, header) do
      { name, content } = Utils.split_http_header(header)
      case name do
        "host" -> %{packet | host: content}
        "cache-control" -> %{packet | cache_control: content}
        "location" -> %{packet | location: content}
        "nt" -> %{packet | nt: content}
        "nts" -> %{packet | nts: content}
        "server" -> %{packet | server: content}
        "usn" -> %{packet | usn: content}

        # Fields contained in M-Search responses:

        # 'st' is basically the same as 'nt' in Notify messages
        "st" -> %{packet | nt: content}
        # Contained for backwards compatibility: ignored
        "ext" -> packet
        # date when response was generated: ignored
        "date" -> packet
        # even if there's a body we'd ignore it
        "content-length" -> packet
      end
    end
  end

  defmodule MSearch do
    alias Ssdp.Packet.Utils

    defstruct [ :type, :host, :man, :mx, :st, :user_agent, :tcpport, :cpfn, :cpuuid ]

    def parse(headers) do
      parse_accumulate(headers, %Ssdp.Packet.MSearch{type: :msearch})
    end

    defp parse_accumulate(headers, packet) do
      case headers do
        [] -> packet
        [head | tail] -> parse_accumulate(tail, add_entry(packet, head))
      end
    end

    defp add_entry(packet, header) do
      { name, content } = Utils.split_http_header(header)
      case name do
        "host" -> %{packet | host: content}
        "man" -> %{packet | man: content}
        "mx" -> %{packet | mx: content}
        "st" -> %{packet | st: content}
        "user-agent" -> %{packet | user_agent: content}
        "tcpport.upnp.org" -> %{packet | tcpport: content}
        "cpfn.upnp.org" -> %{packet | cpfn: content}
        "cpuuid.upnp.org" -> %{packet | cpuuid: content}
      end
    end
  end

  def from_iolist(uhttp_request) do
    from_string(:erlang.iolist_to_binary(uhttp_request))
  end

  def from_string(uhttp_request) do
    [request_line | headers] =
      String.split(uhttp_request, ["\r\n", "\n"], trim: true)
    cond do
      request_line == "NOTIFY * HTTP/1.1" ->
        Ssdp.Packet.Notify.parse(headers)
      # M-Search responses are treated as if they are NOTIFY messages
      request_line == "HTTP/1.1 200 OK" ->
        Ssdp.Packet.Notify.parse(headers)
      request_line == "M-SEARCH * HTTP/1.1" ->
        Ssdp.Packet.MSearch.parse(headers)
    end
  end
end
