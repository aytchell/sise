defmodule Sise.MCast.Supervisor do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Sise.MCast.Listener, name: Sise.MCast.Supervisor},
      {Task.Supervisor, name: Sise.MCast.ProcessorSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
