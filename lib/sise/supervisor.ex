defmodule Sise.Supervisor do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Sise.Cache.Supervisor, name: Sise.Cache.Supervisor},
      {Sise.MCast.Supervisor, name: Sise.MCast.Supervisor},
      {Sise.Search.Supervisor, name: Sise.Search.Supervisor}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
