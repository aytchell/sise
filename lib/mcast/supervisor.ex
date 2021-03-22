defmodule Ssdp.MCast.Supervisor do
# SPDX-License-Identifier: Apache-2.0

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Ssdp.MCast.Listener, name: Ssdp.MCast.Supervisor},
      {Task.Supervisor, name: Ssdp.MCast.ProcessorSupervisor,
        strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
