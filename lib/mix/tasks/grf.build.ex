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
    :output,
    :layouts,
    :passthrough_copies,
    :ignore
  ]

  @default_opts %{
    input: "src",
    output: "_site",
    layouts: "#{File.cwd!()}/lib/layouts",
    passthrough_copies: [],
    ignore: []
  }

  @switches [
    # input directory
    input: :string,
    # output directory
    output: :string,
    # layouts directory
    layouts: :string,
    # passthrough copies (comma separated)
    passthrough_copies: :string,
    # ignore files (comma separated)
    ignore: :string
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

    default_hooks = %{
      before: [],
      after: []
    }

    # Call before hooks
    for hook <- get_app_env(:hooks, default_hooks).before do
      hook.()
    end

    # Passthrough copy files are passed in as a comma separated string of values
    # while in the configuration they are read as a standard Elixir list
    passthrough_copy_args =
      if is_binary(opts.passthrough_copies) do
        String.split(opts.passthrough_copies, ",")
      else
        opts.passthrough_copies
      end

    for arg <- passthrough_copy_args do
      arg
      |> Path.wildcard()
      |> Enum.map(fn path ->
        # e.g. file 'a/b/c/d.js' will be copied to '<output_dir>/a/b/c/d.js'
        if File.dir?(path) do
          File.mkdir_p(output_path <> "/" <> path)
        else
          File.mkdir_p(output_path <> "/" <> Path.dirname(path))
          :ok = File.cp(path, output_path <> "/" <> path)
        end
      end)
    end

    # Ignore files are passed in as a comma separated string of values
    # while in the configuration they are read as a standard Elixir list
    ignore_args =
      if is_binary(opts.passthrough_copies) do
        String.split(opts.passthrough_copies, ",")
      else
        opts.passthrough_copies
      end

    ignore_files =
      for arg <- ignore_args do
        arg
        |> Path.wildcard()
        |> Enum.filter(fn path ->
          not File.dir?(path)
        end)
      end

    files = get_workable_files(input_path) -- ignore_files

    # handle layouts

    try do
      :ets.new(:griffin_build_layouts, [:ordered_set, :public, :named_table])
    rescue
      ArgumentError ->
        :ok
    end

    layouts_dir = opts.layouts
    layout_files = get_layout_files(layouts_dir)
    num_layouts = length(layout_files)

    # compile layout files
    Enum.map(layout_files, &compile_layout/1)

    partial_layouts = get_partial_layout_files(layouts_dir)
    num_partials = length(partial_layouts)

    # compile partials
    partials =
      try do
        Enum.reduce(partial_layouts, %{}, fn filepath, acc ->
          Map.put(
            acc,
            String.to_atom(Path.basename(filepath, Path.extname(filepath))),
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
              file_path = file
              extname = Path.extname(file)
              global_input_dir = input_path
              global_output_dir = output_path

              # TODO switch to parsing every file before rendering them out
              # this will be useful to generate collections and to add useful keys
              # like URL and others as keys to the layout
              # (e.g. being able to do refer @url within the layout)
              {:ok, %{front_matter: front_matter}} = GriffinSSG.parse(File.read!(file))

              file_output_path =
                if Map.has_key?(front_matter, :permalink) do
                  global_output_dir <> "/" <> front_matter.permalink
                else
                  path_basename =
                    if Path.basename(file, extname) == "index" do
                      ""
                    else
                      "/" <> Path.basename(file, extname)
                    end

                  path_relative_to_input_dir =
                    case String.split(Path.dirname(file_path), global_input_dir) do
                      ["", ""] ->
                        ""

                      ["", "/" <> path_relative_to_input_dir] ->
                        "/" <> path_relative_to_input_dir
                    end

                  global_output_dir <> path_relative_to_input_dir <> path_basename
                end

              generate_file(file_path, file_output_path, Path.extname(file))
            end)
          end

        for task <- tasks do
          Task.await(task, :infinity)
        end
      end)

    # Call before hooks
    for hook <- get_app_env(:hooks, default_hooks).after do
      hook.()
    end

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
    file_directory = output_path

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

    layout_assigns =
      filters()
      |> Map.merge(shortcodes())
      |> Map.merge(%{partials: partials, title: "Griffin"})

    output =
      GriffinSSG.render(
        layout,
        %{
          front_matter: frontmatter,
          content: content,
          assigns: layout_assigns
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

  defp get_layout_files(path, extensions \\ [".eex"]) do
    Path.wildcard("#{path}/*.*", match_dot: false)
    |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
    |> Enum.filter(&(Path.extname(&1) in extensions))
  end

  defp get_partial_layout_files(path, extensions \\ [".eex"]) do
    Path.wildcard("#{path}/partials/*.*", match_dot: false)
    |> Enum.filter(&(not String.starts_with?(&1, ["_"])))
    |> Enum.filter(&(Path.extname(&1) in extensions))
  end

  defp compile_layout(filepath) do
    :ets.insert(
      :griffin_build_layouts,
      {Path.basename(filepath, Path.extname(filepath)), EEx.compile_file(filepath)}
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

  defp get_app_env(key, default \\ nil) do
    Application.get_env(:griffin_ssg, key, default)
  end

  defp filters() do
    Map.merge(default_filters(), get_app_env(:filters, %{}))
  end

  defp default_filters() do
    %{
      uppercase: &String.upcase/1,
      lowercase: &String.downcase/1
    }
  end

  defp shortcodes() do
    Map.merge(default_shortcodes(), get_app_env(:shortcodes, %{}))
  end

  defp default_shortcodes() do
    %{
      youtube: fn slug ->
        """
        <iframe width="560" height="315" src="https://www.youtube.com/embed/#{slug}"
                title="YouTube video player" frameborder="0" allow="accelerometer;
                autoplay; clipboard-write; encrypted-media; gyroscope;
                picture-in-picture; web-share" allowfullscreen>
        </iframe>
        """
      end
    }
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
