defmodule Sise.Config do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  @twenty_minutes 20 * 60 * 1_000

  @msearch_ttl_default 2
  @msearch_find_locals_default false
  @msearch_search_target_default "ssdp:all"
  @msearch_repeat_interval_msec_default @twenty_minutes
  @msearch_max_seconds_default 5

  @doc """
  The TTL entry in the IP-header of the M-Search packet

  UPnP/SSDP spec says:
  > "The TTL for the IP packet should default to 2 and should be configurable"
  """
  def msearch_ttl() do
    case Application.fetch_env(:Sise, :msearch_ttl) do
      {:ok, value} -> value
      :error -> @msearch_ttl_default
    end
  end

  @doc """
  Should the IP-Stack report multicast packets from localhost?

  Currently this is not useful as we don't handle incoming multicast
  packets at all.
  """
  def msearch_find_locals() do
    case Application.fetch_env(:Sise, :msearch_find_locals) do
      {:ok, value} -> value
      :error -> @msearch_find_locals_default
    end
  end

  @doc """
  Search target to be used for M-Searches

  Which search target ('st' in SSDP lingo) should be used when sending out an
  M-Search multicast. Other devices will only respond if they somehow fit the
  search target ('ssdp:all' is the catch-all target).
  """
  def msearch_search_target() do
    case Application.fetch_env(:Sise, :msearch_search_target) do
      {:ok, value} -> value
      :error -> @msearch_search_target_default
    end
  end

  @doc """
  The number of milliseconds between two M-Search multicasts attempts

  From "time to time" Sise will send out an M-Search multicast packet via UDP.
  This parameter says, how long the "sleep interval" between two multicasts
  should be. Sise only supports a constant time interval.
  """
  def msearch_repeat_interval_msec() do
    case Application.fetch_env(:Sise, :msearch_repeat_interval_msec) do
      {:ok, value} -> value
      :error -> @msearch_repeat_interval_msec_default
    end
  end

  @doc """
  The number of seconds within which other devices should respond to
  our M-Search request. Should be 1 <= mx <= 5 (according to the spec).
  """
  def msearch_max_seconds() do
    case Application.fetch_env(:Sise, :msearch_max_seconds) do
      {:ok, value} -> value
      :error -> @msearch_max_seconds_default
    end
  end

  @doc """
  In case
  * a UPnP device or service is located on the same machine and
  * announces its ssdp record via localhost and an "outgoing ip address" and
  * uses the same usn for both announcements
  which of the two announcements should we prefer?
  """
  def detect_prefers_localhost() do
    true
  end

  @doc """
  The multicast IP address to be used.
  In the vast majority of cases there's no need to change this and this
  function's purpose is mostly to have a name for this magic value.
  """
  def multicast_addr() do
    {239, 255, 255, 250}
  end

  @doc """
  The multicast UDP port to be used.
  In the vast majority of cases there's no need to change this and this
  function's purpose is mostly to have a name for this magic value.
  """
  def multicast_port() do
    1900
  end
end
