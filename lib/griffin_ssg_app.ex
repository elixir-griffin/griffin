defmodule GriffinSSGApp do
  use Application

  @doc false
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: Griffin.Supervisor)
  end
end
