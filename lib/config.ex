defmodule Ssdp.Config do

  # UPnP/SSDP spec says:
  # "The TTL for the IP packet should default to 2 and should be configurable"
  def msearch_ttl() do
    2
  end

  def msearch_find_locals() do
    false
  end

  def msearch_search_target() do
    "ssdp:all"
  end

  @doc """
  The number of milliseconds between to M-Search multicasts
  """
  def msearch_repeat_interval_msec() do
    # 20 minutes
    20 * 60 * 1_000
  end

  @doc """
  The number of seconds within which other devices should respond to
  our M-Search request. Should be 1 <= mx <= 5
  """
  def msearch_max_seconds() do
    5
  end
end
