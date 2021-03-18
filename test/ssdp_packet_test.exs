defmodule SsdpPacketTest do
  use ExUnit.Case

  def ssdp_notify_dimming do
    """
    NOTIFY * HTTP/1.1\r\n
    Host: 239.255.255.250:1900\r\n
    Cache-Control: max-age=1800\r\n
    Location: http://172.16.195.129:37277/23b0189c-549f-11dc-a7c7-001641597c49.xml\r\n
    Server: Linux/5.4.0-66-generic UPnP/1.0 GUPnP/1.2.3\r\n
    NTS: ssdp:alive\r\n
    NT: urn:schemas-upnp-org:service:Dimming:1\r\n
    USN: uuid:23b0189c-549f-11dc-a7c7-001641597c49::urn:schemas-upnp-org:service:Dimming:1\r\n
    \r\n
    """
  end
  
  test "dimming" do
    packet = SsdpClient.SsdpPacket.from_string(ssdp_notify_dimming())
    assert packet.type == :notify
    assert packet.nts == "ssdp:alive"
    assert packet.nt == "urn:schemas-upnp-org:service:Dimming:1"
    assert packet.host == "239.255.255.250:1900"
    assert packet.server == "Linux/5.4.0-66-generic UPnP/1.0 GUPnP/1.2.3"
    assert packet.usn == "uuid:23b0189c-549f-11dc-a7c7-001641597c49::urn:schemas-upnp-org:service:Dimming:1"
    assert packet.location == "http://172.16.195.129:37277/23b0189c-549f-11dc-a7c7-001641597c49.xml"
    assert packet.cache_control == "max-age=1800"
  end

  def ssdp_msearch_mediaserver do
    """
    M-SEARCH * HTTP/1.1\r\n
    Host: 239.255.255.250:1900\r\n
    Man: "ssdp:discover"\r\n
    ST: urn:schemas-upnp-org:device:MediaServer:1\r\n
    MX: 3\r\n
    User-Agent: Linux/5.4.0-66-generic UPnP/1.0 GUPnP/1.2.3\r\n
    \r\n
    """
  end

  test "mediaserver" do
    packet = SsdpClient.SsdpPacket.from_string(ssdp_msearch_mediaserver())
    assert packet.type == :msearch
    assert packet.host == "239.255.255.250:1900"
    assert packet.man == "\"ssdp:discover\""
    assert packet.st == "urn:schemas-upnp-org:device:MediaServer:1"
    assert packet.mx == "3"
    assert packet.user_agent == "Linux/5.4.0-66-generic UPnP/1.0 GUPnP/1.2.3"
  end


#  test "greets the world" do
#    assert SsdpClient.hello() == :world
#  end
end
