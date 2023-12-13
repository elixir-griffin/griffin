defmodule Mix.Tasks.Grf.Server do
  use Mix.Task

  @shortdoc "Generates a static website and listens for changes."

  @moduledoc """
  Starts up a local development server using plug_cowboy.
  The local server watches for file changes and re-runs grf.build
  on file change, but does not reload the file in the browser.
  This server is NOT meant to be run in production.
  """
  require Logger

  @requirements ["app.config", "grf.build"]
  @default_port "4123"

  @impl Mix.Task
  def run(args) do
    # load code and start dependencies, including cowboy
    {:ok, _} = Application.ensure_all_started([:griffin_ssg])

    port = http_port()

    input_directories = [
      Application.get_env(:griffin_ssg, :input, "src"),
      Application.get_env(:griffin_ssg, :layouts, "lib/layouts")
    ]

    live_reload_watch_dirs = [
      ~r"#{Application.get_env(:griffin_ssg, :output, "_site")}/*"
    ]

    Application.put_env(:plug_live_reload, :patterns, live_reload_watch_dirs)

    on_file_change_callback = fn ->
      # Can we do more clever builds here? (e.g. building only changed files)
      Mix.Tasks.Grf.Build.run([])
    end

    children = [
      {Plug.Cowboy,
       scheme: :http, plug: GriffinSSG.Web.Plug, options: [port: port, dispatch: dispatch()]},
      {GriffinSSG.Filesystem.Watcher, [input_directories, on_file_change_callback]}
    ]

    # disable debug logs from plug_live_reload
    Logger.configure(level: :info)

    Mix.shell().info("Starting webserver on http://localhost:#{port}")
    Supervisor.start_link(children, strategy: :one_for_one, name: Grf.Server.Supervisor)

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
