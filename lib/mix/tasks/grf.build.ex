defmodule Mix.Tasks.Grf.Build do
  use Mix.Task

  @version Mix.Project.config()[:version]
  @shortdoc "Generates a static website with Griffin"
  @extensions [
    # markdown
    ".md",
    ".markdown"
  ]

  @moduledoc """
  Generates a Griffin static site from existing template files

      $ mix grf.build

  A set of files will be written to the configured output directory,
  `_site` by default
  """

  @impl Mix.Task
  def run([]) do
    Mix.Tasks.Compile.run([])
    input_path = Application.fetch_env!(:griffin_ssg, :input_path)
    output_path = Application.fetch_env!(:griffin_ssg, :output_path)

    # Mix.shell().info("Reading files from #{input_path}")
    # Mix.shell().info("Writing files to #{output_path}")

    # check input files
    files = get_workable_files(input_path)

    check_workable_files!(files)

    # handle layouts

    try do
      :ets.new(:griffin_build_layouts, [:ordered_set, :public, :named_table])
    rescue
      ArgumentError ->
        :ok
    end

    layout_files = get_layout_files() ++ get_theme_layout_files()
    num_layouts = length(layout_files)

    # compile layout files
    # any theme layouts will be compiled after project layouts,
    # overwriting project layouts with the same name
    Enum.map(layout_files, &compile_layout/1)

    partial_layouts = get_partial_layout_files() ++ get_theme_partial_layout_files()
    num_partials = length(partial_layouts)

    # compile partials
    partials =
      try do
        Enum.reduce(partial_layouts, %{}, fn filepath, acc ->
          Map.put(
            acc,
            String.to_atom(Path.basename(filepath, ".html.eex")),
            GriffinSSG.compile_layout(filepath)
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

    # handle assets
    output_assets_path = Path.expand("assets", output_path)
    :ok = File.mkdir_p!(output_assets_path)
    assets = File.cp_r!(Path.expand("assets", File.cwd!()), output_assets_path)
    Mix.shell().info("copied #{length(assets)} asset files to #{output_path}")

    # theme
    case Application.get_env(:griffin_ssg, :theme, nil) do
      nil ->
        # no theme selected, no assets to copy
        :ok

      app_name ->
        # copy theme assets, overwriting project assets
        theme_assets =
          File.cp_r!(Path.expand("deps/#{app_name}/assets", File.cwd!()), output_assets_path)

        Mix.shell().info(
          "copied #{length(theme_assets)} asset files from theme #{app_name} to #{output_path}"
        )
    end

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
      :erlang.float_to_binary(time_in_microseconds / (1_000 * files_written), decimals: 1)

    Mix.shell().info(
      "Wrote #{files_written} files in #{time_elapsed} seconds (#{time_per_file}ms each, v#{@version})"
    )
  end

  def run(_) do
    Mix.raise(
      "Unprocessable arguments, please use `mix help grf.build` for documentation on correct usage"
    )
  end

  defp generate_file(input_path, output_path, extname) do
    # Mix.shell().info("reading: #{input_path}")

    {frontmatter, content} = GriffinSSG.parse_file(input_path)

    # create full directory path
    file_directory = "#{output_path}/#{Path.basename(input_path, extname)}"

    # Mix.shell().info("creating path: #{file_directory}")

    file_directory
    |> Path.expand()
    |> File.mkdir_p()

    file_path = "#{file_directory}/index.html"

    # Mix.shell().info("writing: #{file_path} from #{input_path} (#{extension_parser(extname)})")

    # frontmatter|> IO.inspect()

    layout_name = Map.get(frontmatter, :layout, "__fallback__")

    layout =
      :griffin_build_layouts
      |> :ets.lookup(layout_name)
      |> then(fn [{^layout_name, layout}] -> layout end)

    partials =
      :griffin_build_layouts
      |> :ets.lookup(:__partials__)
      |> then(fn [{:__partials__, partials}] -> partials end)

    GriffinSSG.render(file_path, layout,
      frontmatter: frontmatter,
      content: content,
      assigns: %{partials: partials}
    )
  end

  defp print_compiled_layouts(num_layouts, num_partials) do
    Mix.shell().info(
      "Compiled #{num_layouts + num_partials} layouts (#{num_partials} partial#{unless num_partials == 1, do: "s"})"
    )
  end

  defp check_workable_files!(files) do
    if files == [] do
      Mix.raise(
        "No input files found in #{Application.get_env(:griffin_ssg, :input_path, "_site")}, please ensure there are template files in the input path"
      )
    end
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

  defp get_theme_layout_files(extensions \\ [".eex"]) do
    case Application.get_env(:griffin_ssg, :theme, nil) do
      nil ->
        []

      app_name ->
        Path.wildcard("#{File.cwd!()}/deps/#{app_name}/lib/layouts/*.html.eex")
        |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
        |> Enum.filter(&(Path.extname(&1) in extensions))
    end
  end

  defp get_theme_partial_layout_files(extensions \\ [".eex"]) do
    case Application.get_env(:griffin_ssg, :theme, nil) do
      nil ->
        []

      app_name ->
        Path.wildcard("#{File.cwd!()}/deps/#{app_name}/lib/layouts/partials/*.*", match_dot: false)
        |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
        |> Enum.filter(&(Path.extname(&1) in extensions))
    end
  end

  defp compile_layout(filepath) do
    :ets.insert(
      :griffin_build_layouts,
      {Path.basename(filepath, ".html.eex"), GriffinSSG.compile_layout(filepath)}
    )
  end

  defp fallback_html_layout do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title><%= @content %></title>
        <link rel="stylesheet" href="style.css">
      </head>
      <body>
      <%= @content %>
      </body>
    </html>
    """
  end

end
