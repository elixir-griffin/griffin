defmodule GriffinSSG.Plugin.Behaviour do
  @moduledoc """
  This is the behaviour for all plugins.
  """

  @callback init(GriffinSSG.Config.t(), any()) :: GriffinSSG.Config.t()
end