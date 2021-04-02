defmodule Sise do
  # SPDX-License-Identifier: Apache-2.0

  @moduledoc """
  Sise is a library that implements the **si**mple **se**rvice
  discovery protocol (SSDP).

  In its current state the library is only listening for announcements (and
  updates) but it's not able to publish custom device or service information.
  """

  def get_all() do
    Sise.Cache.DeviceDb.get_all()
  end

  def subscribe(notification_type) do
    Sise.Cache.DeviceDb.subscribe(notification_type)
  end

  def subscribe_all() do
    Sise.Cache.DeviceDb.subscribe("all")
  end

  def unsubscribe(notification_type) do
    Sise.Cache.DeviceDb.unsubscribe(notification_type)
  end

  def unsubscribe_all() do
    Sise.Cache.DeviceDb.unsubscribe("all")
  end
end
