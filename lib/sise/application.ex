defmodule Sise.Application do
  # SPDX-License-Identifier: Apache-2.0
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Sise.Supervisor.start_link(name: Sise.Supervisor)
  end
end
