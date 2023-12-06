defmodule Mix.Tasks.Grf.Server do
  use Mix.Task

  @shortdoc "Generates a static website and listens for changes."

  @moduledoc """
  Starts up a local development server using plug_cowboy.
  The local server watches for file changes and re-runs grf.build
  on file change, but does not reload the file in the browser.
  This server is NOT meant to be run in production.
  ## Command line options
    * `--open` - open browser window for each started endpoint
  Furthermore, this task accepts the same command-line options as
  `mix run`.
  For example, to run `grf.server` without recompiling:
      $ mix grf.server --no-compile
  The `--no-halt` flag is automatically added.
  Note that the `--no-deps-check` flag cannot be used this way,
  because Mix needs to check dependencies to find `grf.server`.
  To run `grf.server` without checking dependencies, you can run:
      $ mix do deps.loadpaths --no-deps-check, grf.server
  """

  @requirements ["app.start", "grf.build"]
  @default_port "4123"

  @impl Mix.Task
  def run(args) do
    port = http_port()
    Mix.shell().info("Starting webserver on http://localhost:#{port}")
    input_directories = Application.get_env(:griffin_ssg, :input, "src")

    Application.put_env(:plug_live_reload, :patterns, [
      ~r"#{Application.get_env(:griffin_ssg, :output)}/*"
    ])

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: GriffinSSG.Web.Plug,
       options: [port: http_port(), dispatch: dispatch()]},
      {GriffinSSG.Filesystem.Watcher, [input_directories]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Grf.Server.Supervisor)

    # Mix.Tasks.Run.run(open_args(args) ++ run_args())
    Process.sleep(:infinity)
  end

  def http_port do
    fallback =
      "GRIFFIN_HTTP_PORT"
      |> System.get_env(@default_port)
      |> Integer.parse()
      |> then(fn {integer, _remainder} -> integer end)

    Application.get_env(:griffin_ssg, :http_port, fallback)
  end

  def dispatch() do
    [
      {:_,
       [
         {"/plug_live_reload/socket", PlugLiveReload.Socket, []},
         {:_, Plug.Cowboy.Handler, {GriffinSSG.Web.Plug, []}}
       ]}
    ]
  end
end
