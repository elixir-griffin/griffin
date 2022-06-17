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
    elixir_version_check!()

    case parse_opts(args) do
      {nil, []} ->
        Mix.Tasks.Help.run(["grf.new"])

      {opts, [base_path | _]} ->
        generate(base_path, opts)
    end
  end

  defp generate(base_path, opts) do
    base_path
    |> Project.new(opts)
    |> validate_project()
    |> Generator.run()
    |> prompt_to_install_deps()
  end

  defp validate_project(%Project{} = project) do
    check_app_name!(project.app_name)
    check_directory_existence!(project.path)
    check_module_name_validity!(project.module)
    check_module_name_availability!(project.module)
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

  defp prompt_to_install_deps(%Project{} = project) do
    path = project.path

    install? =
      Keyword.get_lazy(project.opts, :install, fn ->
        Mix.shell().yes?("\nFetch and install dependencies?")
      end)

    cd_step = ["$ cd #{relative_app_path(path)}"]

    maybe_cd(path, fn ->
      mix_step = install_mix(project, install?)

      if mix_step == [] and rebar_available?() do
        cmd(project, "mix deps.compile")
      end

      print_missing_steps(cd_step ++ mix_step)

      print_mix_info()
    end)
  end

  defp maybe_cd(path, func), do: path && File.cd!(path, func)

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @arg_types) do
      {opts, argv, []} ->
        {opts, argv}
      {_opts, _argv, [switch | _]} ->
        Mix.raise "Invalid option: " <> switch_to_string(switch)
    end
  end
  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp install_mix(project, install?) do
    maybe_cmd(project, "mix deps.get", true, install? && hex_available?())
  end

  defp hex_available? do
    Code.ensure_loaded?(Hex)
  end

  defp rebar_available? do
    Mix.Rebar.rebar_cmd(:rebar3)
  end

  defp print_missing_steps(steps) do
    Mix.shell().info """
    We are almost there! The following steps are missing:
        #{Enum.join(steps, "\n    ")}
    """
  end

  defp print_mix_info() do
    Mix.shell().info """
    Compile and generate your static site with:
        $ mix grf.build
    Spawn a tiny HTTP server to serve the generated files:
        $ mix grf.server
    You can also run the HTTP server inside IEx (Interactive Elixir) as:
        $ iex -S mix grf.server
    """
  end

  defp relative_app_path(path) do
    case Path.relative_to_cwd(path) do
      ^path -> Path.basename(path)
      rel -> rel
    end
  end

  ## Helpers

  defp maybe_cmd(project, cmd, should_run?, can_run?) do
    cond do
      should_run? && can_run? ->
        cmd(project, cmd)
      should_run? ->
        ["$ #{cmd}"]
      true ->
        []
    end
  end

  defp cmd(%Project{} = project, cmd) do
    Mix.shell().info [:green, "* running ", :reset, cmd]
    case Mix.shell().cmd(cmd, cmd_opts(project)) do
      0 ->
        []
      _ ->
        ["$ #{cmd}"]
    end
  end

  defp cmd_opts(%Project{} = project) do
    if Project.verbose?(project) do
      []
    else
      [quiet: true]
    end
  end

  defp check_module_name_validity!(name) do
    unless inspect(name) =~ Regex.recompile!(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
      Mix.raise "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect name}"
    end
  end

  defp check_module_name_availability!(name) do
    [name]
    |> Module.concat()
    |> Module.split()
    |> Enum.reduce([], fn name, acc ->
        mod = Module.concat([Elixir, name | acc])
        if Code.ensure_loaded?(mod) do
          Mix.raise "Module name #{inspect mod} is already taken, please choose another name"
        else
          [name | acc]
        end
    end)
  end

  defp check_directory_existence!(path) do
    if File.dir?(path) and not Mix.shell().yes?("The directory #{path} already exists. Are you sure you want to continue?") do
      Mix.raise "Please select another directory for installation."
    end
  end

  defp elixir_version_check! do
    unless Version.match?(System.version(), "~> 1.13") do
      Mix.raise "Phoenix v#{@version} requires at least Elixir v1.13.\n " <>
                "You have #{System.version()}. Please update accordingly"
    end
  end

end
