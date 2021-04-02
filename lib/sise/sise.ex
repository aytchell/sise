defmodule Sise do
  # SPDX-License-Identifier: Apache-2.0

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
