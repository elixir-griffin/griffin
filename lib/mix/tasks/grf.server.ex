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

  @switches [
    port: :integer
  ]

  @aliases [
    p: :port
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _parsed} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)
    opts = Map.new(opts)

    # load code and start dependencies, including cowboy
    {:ok, _} = Application.ensure_all_started([:griffin_ssg])

    port = http_port(opts)

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

  # refactor: consider having a centralized place for reading configuration values
  # that are overridable in different ways.
  def http_port(opts) do
    Map.get(opts, :port) || Application.get_env(:griffin_ssg, :http_port) ||
      parse_int(System.get_env("GRIFFIN_HTTP_PORT", @default_port))
  end

  defp parse_int(string) do
    {integer, _remainder} = Integer.parse(string)
    integer
  end

  defp dispatch() do
    [
      {:_,
       [
         {"/plug_live_reload/socket", PlugLiveReload.Socket, []},
         {:_, Plug.Cowboy.Handler, {GriffinSSG.Web.Plug, []}}
       ]}
    ]
  end
end
