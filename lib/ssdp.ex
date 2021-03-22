defmodule Ssdp do
# SPDX-License-Identifier: Apache-2.0

  use Application

  def multicast_addr() do
    {239, 255, 255, 250}
  end

  def multicast_port() do
    1900
  end

  @impl true
  def start(_type, _args) do
    Ssdp.Supervisor.start_link(name: Ssdp.Supervisor)
  end
end
