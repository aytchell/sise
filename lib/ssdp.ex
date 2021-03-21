defmodule Ssdp do
# SPDX-License-Identifier: Apache-2.0

  use Application

  @impl true
  def start(_type, _args) do
    Ssdp.Supervisor.start_link(name: Ssdp.Supervisor)
  end
end
