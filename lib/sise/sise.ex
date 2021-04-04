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

  @doc """
  Get discovered device and service information

  Call this function to get information about discovered devices and services.
  """
  @spec get(nt()) :: [Sise.Discovery.t()]
  def get(notification_type) do
    Sise.Cache.DeviceDb.get(notification_type)
  end

  @doc """
  Subscribe to receive notifications about discoveries

  When calling this function, the caller will
  - receive a notification message of type `:ssdp_add` for every already known
    discovery
  - receive a message for every change in the future

  It is possible to subscribe to multiple different notification types.

  The possible notification messages to be received are these:
  ```
  {:ssdp_add, Sise.Discovery.t()}
  ```
  This message informs that a new device or service has been discovered. It
  will contain a struct with all available information on the discovery.

  ```
  {:ssdp_update, Sise.Discovery.t(), [{atom(), String.t(), String.t()}]}
  ```
  Informs the listener that the available information about a known
  device/service has changed. The message will carry the new version of
  the Discovery struct. It will also carry a list with the differences
  between the old and the new device/service information.

  ```
  {:ssdp_delete, Sise.Discovery.t()}
  ```

  Informs that a device/service is no longer available. The message will
  carry the last known version of the Discovery struct.
  See also `Sise.Discovery.diff/2`.
  """
  @spec subscribe(nt()) :: nil
  def subscribe(notification_type) do
    Sise.Cache.DeviceDb.subscribe(notification_type)
  end

  @doc """
  Unsubribe from notifications about discoveries.

  Note that the notification mechanism does a very simple matching for
  notification types. If you subscribe to multiple concrete services/devices
  and then `unsubscribe(:all)`, they will all be removed.
  However if you subscribe to `:all` services/devices and then unsubscribe from 
  a concrete one you will still get all notifications.
  """
  @spec unsubscribe(nt()) :: nil
  def unsubscribe(notification_type) do
    Sise.Cache.DeviceDb.unsubscribe(notification_type)
  end
end
