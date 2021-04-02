defmodule Sise do
  # SPDX-License-Identifier: Apache-2.0

  defmodule Discovery do
    @enforce_keys [:location, :nt, :usn]
    defstruct [:location, :nt, :usn, :server,
      :boot_id, :config_id, :secure_location, :next_boot_id]
  end

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
