defmodule Ssdp.SsdpPacket do
# SPDX-License-Identifier: Apache-2.0

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

  defmodule Notify do
    import Ssdp.SsdpPacket.Utils, only: [split_http_header: 1]

    defstruct [ :type, :location, :nt, :nts, :server, :usn, :host, :cache_control ]

    def parse(headers) do
      parse_accumulate(headers, %Ssdp.SsdpPacket.Notify{type: :notify})
    end

    defp parse_accumulate(headers, packet) do
      case headers do
        [] -> packet
        [head | tail] -> parse_accumulate(tail, add_entry(packet, head))
      end
    end

    defp add_entry(packet, header) do
      { name, content } = split_http_header(header)
      case name do
        "host" -> %{packet | host: content}
        "cache-control" -> %{packet | cache_control: content}
        "location" -> %{packet | location: content}
        "nt" -> %{packet | nt: content}
        "nts" -> %{packet | nts: content}
        "server" -> %{packet | server: content}
        "usn" -> %{packet | usn: content}
      end
    end
  end

  defmodule MSearch do
    import Ssdp.SsdpPacket.Utils, only: [split_http_header: 1]

    defstruct [ :type, :host, :man, :mx, :st, :user_agent, :tcpport, :cpfn, :cpuuid ]

    def parse(headers) do
      parse_accumulate(headers, %Ssdp.SsdpPacket.MSearch{type: :msearch})
    end

    defp parse_accumulate(headers, packet) do
      case headers do
        [] -> packet
        [head | tail] -> parse_accumulate(tail, add_entry(packet, head))
      end
    end

    defp add_entry(packet, header) do
      { name, content } = split_http_header(header)
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
        Ssdp.SsdpPacket.Notify.parse(headers)
      request_line == "M-SEARCH * HTTP/1.1" ->
        Ssdp.SsdpPacket.MSearch.parse(headers)
    end
  end
end
