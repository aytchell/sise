defmodule Sise.Cache.Supervisor do
  # SPDX-License-Identifier: Apache-2.0

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Sise.Cache.DeviceDb, name: Sise.Cache.DeviceDb},
      {Sise.Cache.Notifier, name: Sise.Cache.Notifier}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
