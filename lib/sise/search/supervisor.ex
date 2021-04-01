defmodule Sise.Search.Supervisor do
  # SPDX-License-Identifier: Apache-2.0

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Sise.Search.Sender, name: Sise.Search.Sender},
      {Task.Supervisor, name: Sise.Search.ProcessorSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
