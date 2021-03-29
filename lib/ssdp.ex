defmodule Ssdp do
# SPDX-License-Identifier: Apache-2.0

  use Application

  @impl true
  def start(_type, _args) do
    Ssdp.Supervisor.start_link(name: Ssdp.Supervisor)
  end

  def get_all() do
    Ssdp.DeviceDb.get_all()
  end

  def subscribe(notification_type) do
    Ssdp.DeviceDb.subscribe(notification_type)
  end

  def multicast_addr() do
    {239, 255, 255, 250}
  end

  def multicast_port() do
    1900
  end
end
