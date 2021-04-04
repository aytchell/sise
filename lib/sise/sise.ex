defmodule Sise do
  # SPDX-License-Identifier: Apache-2.0

  @moduledoc """
  Sise is a library that implements the **si**mple **se**rvice
  discovery protocol (SSDP).

  Sise will listen on the network for announcements of available UPnP devices
  and services. Additionally it will send out search requests from time to
  time. All discovered devices will be stored by Sise.
  
  A client of this
  library can either fetch the discoveries or subscribe for notifications (on
  subscription the listener will be called with the already discovered
  devices/services).
  """

  @typedoc """
  Notification type

  This type is used as a parameter to select the 'notification type' the
  caller is interested in.

  If atom `:all` is given the client will get _all_ of the discoveries.
  Whereas if a string is given it is interpreted as the exact notification
  type as given by the peer.

  Examples for UPnP notification types are `"upnp:rootdevice"` or
  `"urn:schemas-upnp-org:service:SwitchPower:1"`.
  """
  @type nt :: :all | String.t()

  @spec get(nt()) :: [Sise.Discovery.t()]
  def get(notification_type) do
    Sise.Cache.DeviceDb.get(notification_type)
  end

  @spec subscribe(nt()) :: nil
  def subscribe(notification_type) do
    Sise.Cache.DeviceDb.subscribe(notification_type)
  end

  def unsubscribe(notification_type) do
    Sise.Cache.DeviceDb.unsubscribe(notification_type)
  end

  def unsubscribe_all() do
    Sise.Cache.DeviceDb.unsubscribe("all")
  end
end
