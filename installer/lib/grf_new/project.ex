defmodule Grf.New.Project do
  @moduledoc false
  defstruct [:app_name, :module, :opts, :path, :version]

  alias Grf.New.Project

  @version Mix.Project.config()[:version]

  def new(project_path, opts) do
    project_path = Path.expand(project_path)
    app = opts[:app] || Path.basename(project_path)
    app_mod = Module.concat([opts[:module] || Macro.camelize(app)])

    %Project{
      app_name: app,
      module: app_mod,
      opts: opts,
      path: project_path,
      version: @version
    }
  end

  def verbose?(%Project{opts: opts}) do
    Keyword.get(opts, :verbose, false)
  end
end
