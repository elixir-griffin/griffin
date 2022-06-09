defmodule Mix.Tasks.Grf.New do
  @moduledoc """
  Creates a new Griffin project.

  It expects the path of the project as an argument.

      $ mix grf.new PATH

  A project at the given PATH will be created.

  ## Options

    * `--input-path` - configures Griffin to search for source
      files on a given path
    * `--output-path` - configures Griffin to write generated
      files to a given path
    * `-v`, `--version` - prints the Griffin installer version

  ## Installation

  `mix grf.new` by default prompts you to fetch and install your
  dependencies. You can enable this behaviour by passing the
  `--install` flag or disable it with the `--no-install` flag.

  ## Examples

      $ mix grf.new blog

  Is equivalent to:

      $ mix grf.new blog --input-path priv/src --output-path _site
  """
  use Mix.Task
  # alias Grf.New.{Generator, Project, Single, Web}

  @version Mix.Project.config()[:version]
  @shortdoc "Creates a new Griffin v#{@version} application"

  @arg_types [
    input_path: :string,
    output_path: :string,
    module: :string
  ]

  alias Grf.New.{Generator, Project}

  @impl Mix.Task
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Griffin installer v#{@version}")
  end

  def run(args) do
    case parse_opts(args) do
      {nil, []} ->
        Mix.Tasks.Help.run(["grf.new"])

      {name, opts} ->
        Project.new([{:app_name, name} | opts])
        |> validate_project()
        |> Generator.run()
    end
  end

  defp parse_opts(args) do
    case OptionParser.parse(args, strict: @arg_types) do
      {opts, [name], []} ->
        {name, opts}

      {_, [], []} ->
        {nil, []}

      {_, args, []} ->
        Mix.raise("Invalid project name: #{Enum.join(args, " ")}")

      {_opts, _args, [{arg, nil} | _]} ->
        Mix.raise("Invalid argument: #{arg}")

      {_opts, _args, [{arg, value} | _]} ->
        Mix.raise("Invalid argument: #{arg}=#{value}")
    end
  end

  defp validate_project(%Project{} = project) do
    check_app_name!(project.app_name)

    project
  end

  defp check_app_name!(name) do
    unless name =~ Regex.recompile!(~r/^[a-z][\w_]*$/) do
      Mix.raise(
        "Application name must start with a letter and have only lowercase " <>
          "letters, numbers and underscore, got: #{inspect(name)}"
      )
    end
  end
end
