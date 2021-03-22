defmodule Ssdp.Supervisor do
# SPDX-License-Identifier: Apache-2.0

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Ssdp.DeviceDb, name: Ssdp.DeviceDb},
      {Ssdp.MCast.Supervisor, name: Ssdp.MCast.Supervisor},
      {Ssdp.Search.Supervisor, name: Ssdp.Search.Supervisor}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
