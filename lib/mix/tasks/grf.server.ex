defmodule Mix.Tasks.Grf.Server do
  use Mix.Task

  @shortdoc "Generates a static website and listens for changes."

  @moduledoc """
  Starts the application by configuring all endpoints servers to run.
  Note: to start the endpoint without using this mix task you must set
  `server: true` in your `Phoenix.Endpoint` configuration.
  ## Command line options
    * `--open` - open browser window for each started endpoint
  Furthermore, this task accepts the same command-line options as
  `mix run`.
  For example, to run `phx.server` without recompiling:
      $ mix phx.server --no-compile
  The `--no-halt` flag is automatically added.
  Note that the `--no-deps-check` flag cannot be used this way,
  because Mix needs to check dependencies to find `phx.server`.
  To run `phx.server` without checking dependencies, you can run:
      $ mix do deps.loadpaths --no-deps-check, phx.server
  """

  @impl Mix.Task
  def run(args) do
    port = GriffinSSGApp.http_port
    IO.puts "Starting webserver on #{port}"
    Application.put_env(:griffin_ssg, :server, true, persistent: true)
    Mix.Tasks.Run.run(open_args(args) ++ run_args())
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end

  defp open_args(args) do
    if "--open" in args do
      Application.put_env(:griffin_ssg, :browser_open, true)
      args -- ["--open"]
    else
      args
    end
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end
end
