defmodule Mix.Tasks.Grf.Build do
  @shortdoc "Generates a static website with Griffin"

  @moduledoc """
  Generates a Griffin static site from existing template files

      $ mix grf.build

  A set of files will be written to the configured output directory,
  `_site` by default
  """

  use Mix.Task

  @version Mix.Project.config()[:version]

  @extensions [
    # markdown
    ".md",
    ".markdown"
  ]

  @all_options [
    :input,
    :output
  ]

  @default_opts %{
    input: "src",
    output: "_site"
  }

  @switches [
    # input directory
    input: :string,
    # output directory
    output: :string
  ]

  @aliases [
    in: :input,
    out: :output
  ]

  @impl Mix.Task
  def run(args, _test_opts \\ []) do
    {opts, _parsed} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

    # Configuration hierarchy:
    # Environment Variables > Command Line Arguments > Application Config > Defaults

    opts =
      @default_opts
      |> Map.merge(application_config())
      |> Map.merge(Enum.into(opts, %{}))
      |> Map.merge(environment_config())

    input_path = opts.input
    output_path = opts.output

    files = get_workable_files(input_path)

    # handle layouts

    try do
      :ets.new(:griffin_build_layouts, [:ordered_set, :public, :named_table])
    rescue
      ArgumentError ->
        :ok
    end

    layout_files = get_layout_files()
    num_layouts = length(layout_files)

    # compile layout files
    Enum.map(layout_files, &compile_layout/1)

    partial_layouts = get_partial_layout_files()
    num_partials = length(partial_layouts)

    # compile partials
    partials =
      try do
        Enum.reduce(partial_layouts, %{}, fn filepath, acc ->
          Map.put(
            acc,
            String.to_atom(Path.basename(filepath, ".html.eex")),
            EEx.compile_file(filepath)
          )
        end)
      rescue
        Enum.EmptyError ->
          %{}
      end

    :ets.insert(:griffin_build_layouts, {:__partials__, partials})

    print_compiled_layouts(num_layouts, num_partials)

    # compile fallback layout
    :ets.insert(
      :griffin_build_layouts,
      {"__fallback__", EEx.compile_string(fallback_html_layout())}
    )

    # Mix.shell().info("workable files #{get_workable_files(input_path)}")

    # Mix.shell().info("workable layouts #{get_layout_files(input_path)}")

    {time_in_microseconds, response} =
      :timer.tc(fn ->
        tasks =
          for file <- files do
            Task.async(fn ->
              generate_file(file, output_path, Path.extname(file))
            end)
          end

        for task <- tasks do
          Task.await(task, :infinity)
        end
      end)

    files_written = length(response)
    time_elapsed = :erlang.float_to_binary(time_in_microseconds / 1_000_000, decimals: 2)

    time_per_file =
      if files_written > 0 do
        :erlang.float_to_binary(time_in_microseconds / (1_000 * files_written), decimals: 1)
      else
        0
      end

    Mix.shell().info(
      "Wrote #{files_written} files in #{time_elapsed} seconds (#{time_per_file}ms each, v#{@version})"
    )
  end

  defp generate_file(input_path, output_path, extname) do
    Mix.shell().info("reading: #{input_path}")

    parse_result =
      input_path
      |> File.read!()
      |> GriffinSSG.parse()

    if {:error, :parsing_front_matter_failed} == parse_result do
      Mix.raise("File parsing failed for file #{input_path}")
    end

    {:ok, %{front_matter: frontmatter, content: content}} =
      input_path
      |> File.read!()
      |> GriffinSSG.parse()

    # create full directory path
    file_directory = "#{output_path}/#{Path.basename(input_path, extname)}"

    Mix.shell().info("creating path: #{file_directory}")

    file_directory
    |> Path.expand()
    |> File.mkdir_p()

    file_path = "#{file_directory}/index.html"

    Mix.shell().info("writing: #{file_path} from #{input_path} (#{extension_parser(extname)})")

    frontmatter = frontmatter || %{}

    layout_name = Map.get(frontmatter, :layout, "__fallback__")

    layout =
      :griffin_build_layouts
      |> :ets.lookup(layout_name)
      |> then(fn [{^layout_name, layout}] -> layout end)

    partials =
      :griffin_build_layouts
      |> :ets.lookup(:__partials__)
      |> then(fn [{:__partials__, partials}] -> partials end)

    output =
      GriffinSSG.render(
        layout,
        %{
          front_matter: frontmatter,
          content: content,
          assigns: %{partials: partials, title: "Griffin"}
        }
      )

    File.write!(file_path, output)

    try do
    rescue
      MatchError ->
        # file parsing failed
        Mix.raise("File parsing failed for file #{input_path}")
    end
  end

  defp print_compiled_layouts(num_layouts, num_partials) do
    Mix.shell().info(
      "Compiled #{num_layouts + num_partials} layouts (#{num_partials} partial#{unless num_partials == 1, do: "s"})"
    )
  end

  defp extension_parser(ext) when ext in [".md", ".markdown"] do
    "markdown"
  end

  defp get_workable_files(input_path, extensions \\ @extensions) do
    Path.wildcard("#{input_path}/**/*.*", match_dot: false)
    |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
    # |> Enum.map(&Path.expand/1)
    |> Enum.filter(&(Path.extname(&1) in extensions))
  end

  defp get_layout_files(extensions \\ [".eex"]) do
    Path.wildcard("#{File.cwd!()}/lib/layouts/*.*", match_dot: false)
    |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
    |> Enum.filter(&(Path.extname(&1) in extensions))
  end

  defp get_partial_layout_files(extensions \\ [".eex"]) do
    Path.wildcard("#{File.cwd!()}/lib/layouts/partials/*.*", match_dot: false)
    |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
    |> Enum.filter(&(Path.extname(&1) in extensions))
  end

  defp compile_layout(filepath) do
    :ets.insert(
      :griffin_build_layouts,
      {Path.basename(filepath, ".html.eex"), EEx.compile_file(filepath)}
    )
  end

  defp application_config do
    @all_options
    |> Enum.map(fn option -> {option, get_app_env(option)} end)
    |> Enum.into(%{})
    |> Map.filter(fn {_, v} -> not is_nil(v) end)
  end

  defp environment_config do
    @all_options
    |> Enum.map(fn option -> {option, get_env(option)} end)
    |> Enum.into(%{})
    |> Map.filter(fn {_, v} -> not is_nil(v) end)
  end

  defp get_env(key) do
    key
    |> Atom.to_string()
    |> String.upcase()
    |> then(fn key -> "GRIFFIN_" <> key end)
    |> System.get_env()
  end

  defp get_app_env(key) do
    Application.get_env(:griffin_ssg, key)
  end

  defp fallback_html_layout do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title><%= @title %></title>
        <link rel="stylesheet" href="style.css">
      </head>
      <body>
      <%= @content %>
      </body>
    </html>
    """
  end
end
