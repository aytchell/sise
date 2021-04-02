defmodule Sis.Packet.Parse do
  # SPDX-License-Identifier: Apache-2.0

  def from_iolist(uhttp_request) do
    from_string(:erlang.iolist_to_binary(uhttp_request))
  end

  def from_string(uhttp_request) do
    [request_line | headers] = String.split(uhttp_request, ["\r\n", "\n"], trim: true)

    cond do
      request_line == "NOTIFY * HTTP/1.1" ->
        parse(%Sise.Packet.Raw{type: :notify}, headers)

      # M-Search responses are treated as if they are NOTIFY messages
      request_line == "HTTP/1.1 200 OK" ->
        parse(%Sise.Packet.Raw{type: :notify}, headers)

      request_line == "M-SEARCH * HTTP/1.1" ->
        parse(%Sise.Packet.Raw{type: :msearch}, headers)
    end
  end

  defp parse(packet, headers) do
    case headers do
      [] -> packet
      [next | tail] -> parse(add_header(packet, next), tail)
    end
  end

  defp add_header(packet, header) do
    {name, content} = split_http_header(header)

    case name do
      "location" -> %{packet | location: content}
      "nt" -> %{packet | nt: content}
      "usn" -> %{packet | usn: content}
      "server" -> %{packet | server: content}

      "bootid.upnp.org" -> %{packet | boot_id: content}
      "configid.upnp.org" -> %{packet | config_id: content}
      "securelocation.upnp.org" -> %{packet | secure_location: content}
      "nextbootid.upnp.org" -> %{packet | next_boot_id: content}

      "host" -> %{packet | host: content}
      "nts" -> %{packet | nts: content}
      "cache-control" -> %{packet | cache_control: content}

        # 'st' ("search target") is used in msearch-requests to indicate the
        # desired service or device.
        # It is also used in m-search responses where it's basically the same as 'nt'
      "st" -> %{packet | nt: content, st: content}

      "man" -> %{packet | man: content}
      "mx" -> %{packet | mx: content}
      "user-agent" -> %{packet | user_agent: content}
      "tcpport.upnp.org" -> %{packet | tcpport: content}
      "cpfn.upnp.org" -> %{packet | cpfn: content}
      "cpuuid.upnp.org" -> %{packet | cpuuid: content}
    end
  end

  defp split_http_header(header) do
    [name | [content]] = String.split(header, ":", parts: 2)
    fn x -> String.trim(x) end

    {
      String.downcase(String.trim(name), :ascii),
      String.trim(content)
    }
  end
end
