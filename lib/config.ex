defmodule Ssdp.Config do

  @two_minutes 2 * 60 * 1_000
  @twenty_minutes 20 * 60 * 1_000

  @msearch_ttl_default                  2
  @msearch_find_locals_default          false
  @msearch_search_target_default        "ssdp:all"
  @msearch_repeat_interval_msec_default @two_minutes
  @msearch_max_seconds_default          5

  # UPnP/SSDP spec says:
  # "The TTL for the IP packet should default to 2 and should be configurable"
  def msearch_ttl() do
    case Application.fetch_env(:Ssdp, :msearch_ttl) do
      {:ok, value} -> value
      :error -> @msearch_ttl_default
    end
  end

  def msearch_find_locals() do
    case Application.fetch_env(:Ssdp, :msearch_find_locals) do
      {:ok, value} -> value
      :error -> @msearch_find_locals_default
    end
  end

  def msearch_search_target() do
    case Application.fetch_env(:Ssdp, :msearch_search_target) do
      {:ok, value} -> value
      :error -> @msearch_search_target_default
    end
  end

  @doc """
  The number of milliseconds between to M-Search multicasts
  """
  def msearch_repeat_interval_msec() do
    case Application.fetch_env(:Ssdp, :msearch_repeat_interval_msec) do
      {:ok, value} -> value
      :error -> @msearch_repeat_interval_msec_default
    end
  end

  @doc """
  The number of seconds within which other devices should respond to
  our M-Search request. Should be 1 <= mx <= 5
  """
  def msearch_max_seconds() do
    case Application.fetch_env(:Ssdp, :msearch_max_seconds) do
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
