defmodule Sise.Discovery do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc """
  A struct for describing found devices or services together with some
  useful functions
  """

  @enforce_keys [:location, :nt, :usn]
  defstruct [:location, :nt, :usn, :server,
    :boot_id, :config_id, :secure_location, :next_boot_id]

  @typedoc """
  Describes a discovered device or service

  This struct contains the HTTP header values from either an SSDP
  notify message or an MSearch-response. So this describes a device or service
  announced by "someone else".

  The fields (accorings to "UPnP Device Architecture v2.0) have the following
  meaning:

  - `boot_id:` represents the boot instance of the device expressed according
    to a monotonically increasing value. Its field value shall be a
    non-negative integer that shall be
    increased on each initial announce of the UPnP device.

    Control points can use this header field to detect the case when a device
    leaves and rejoins the network ("reboots" in UPnP terms). It can be used by
    control points for a number of purposes such as re-establishing desired
    event subscriptions, checking for changes to the device state that were not
    evented since the device was off-line.

  - `config_id:` contains a non-negative integer value which represents "the
    configuration" of a UPnP device. The configuration of a root device
    consists of the following information: the DDD of the root device and all
    its embedded devices, and the SCPDs of all the contained services. If any
    part of the configuration changes, the `config_id:` field value shall be
    changed. So control points can use this value to decide if any downloaded
    and cache information about the device is still valid or not.

  - `location:` contains a URL to the UPnP description of the root
    device. Normally the host portion contains a literal IP address rather
    than a domain name in unmanaged networks. Specified by UPnP vendor. Single
    absolute URL (see RFC 3986).

  - `next_boot_id:` is contained if the device sends an update. The device
    will then send the old `boot_id:` so a control point can recognize it
    _plus_ this `next_boot_id:` which will then (and for all subsequent
    announcements) be the valid `boot_id:`.

  - `nt:` contains the notification type. Please consult the spec for detailed
    information

  - `secure_location:` provides a base URL with "https:" for the scheme
    component and indicate the correct "port" subcomponent in the "authority"
    component for a TLS connection. Because the scheme and authority components
    are not included in relative URLs, these components are obtained from the
    base URL provided by either `location:` or `secure_location:`.

  - `server:` vendor provided description of the UPnP software running on the
    device

  - `usn:` contains "Unique Service Name". Identifies a unique instance of a
    device or service. Please consult th spec for detailed information.
  """
  @type t :: %__MODULE__{
    location: String.t,
    nt: String.t,
    usn: String.t,
    server: nil | String.t,
    boot_id: nil | String.t,
    config_id: nil | String.t,
    secure_location: nil | String.t,
    next_boot_id: nil | String.t
  }


  @doc """
  Merge two discovery packets; uses `on_top`'s values if available
  and `base` as default

  One packet provides the "base values" the other one provides "updates"
  on top of the base. If for any key there's no "updated" value then
  the base value is used.
  """
  def merge(base, on_top) do
    Map.merge(base, on_top,
      fn _k, base_val, on_top_val ->
        if is_nil(on_top_val) do
          base_val
        else
          on_top_val
        end
      end)
  end
end