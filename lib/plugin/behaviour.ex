defmodule GriffinSSG.Plugin.Behaviour do
  @moduledoc """
  The behaviour for a Griffin Plugin.
  A Plugin is a stateful process that is started at the beginning of the
  Griffin build run and that requests callbacks at specific stages of the build
  run by setting up hooks. The arguments passed in to each callback depend on
  the hook itself, see `GriffinSSG.hooks()` for more information on hooks.

  ## Process instances
  At this moment, Plugins functions are called globally, e.g. `MyPlugin.list_hooks()`.
  This assumes there won't be multiple instances of the same Plugin.

  ## Errors
  Plugins are expected to return errors and not raise if there are issues, so
  that the global Griffin run process can show a human friendly error message
  and gracefully terminate.
  """

  @doc """
  The Plugin start_link function. People creating plugins are encouraged to use
  GenServers for their implementation.
  """
  @callback start_link(griffin_config :: GriffinSSG.Config.t(), plugin_opts :: any()) ::
              {:ok, pid()} | {:error, reason :: atom()}

  @doc """
  Returns a list of Griffin hooks that the Plugin requires.
  """
  @callback list_hooks() :: GriffinSSG.hooks()
end
