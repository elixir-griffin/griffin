defmodule Mix.Tasks.Grf.Build do
  @shortdoc "Generates a static website with Griffin"

  @moduledoc """
  Generates a static website from template and layout files.

      $ mix grf.build [--input INPUT] [--output OUTPUT]

  Template and layout files will be read from INPUT directory and sub-folders,
  and output generated content to the OUTPUT directory.

  ## Options

    * `-in`, `--input` - the path to the input directory. Defaults to `src`.

    * `-out`, `--output` - the directory where Griffin will write files to.
      Defaults to `_site`

    * `--layouts` - the directory where the layout and partials files are kept.
      Defaults to `lib/layouts`.

    * `--passthrough-copies` - comma separated list of directories or files to
      copy directly to the output directory without processing.
      Supports wildcard paths using `Path.wildcard/1` Useful for assets files.

    * `--ignore` - comma separated list of directories or files to ignore
      inside the input directory.

    * `--config` - the path to the configuration file

    * `--dry-run` - disables writing to the file system.
      Useful for tests and debugging.

    * `--quiet` - print minimal console output

    * `--debug` - print additional debug information



  ## Passthrough copy

  Passthrough copy files are files that shouldn't be processed but simply
  copied over to the output directory. This is useful for assets like images,
  fonts, JavaScript and CSS.
  A list of comma separated file or wildcard paths may be provided via the
  `--passthrough-copies` option. Here's an example:

      $ mix grf.build --passthrough-copies=assets/js,fonts,images/*.{png,jpeg}

  This command will copy all files in the `assets/js`, `fonts` and all PNG
  and JPEG images in the `images` directory over to the same path relative
  to the output directory. In the above example and assuming the default
  `_site` output directory, Griffin would copy files to `_site/assets/js`,
  `_site/fonts` and `_site/images` directories, respectively.
  Wildcard paths are expanded by `Path.wildcard/1` and thus all options that
  it supports can be used to build wildcard paths.


  > #### About passthrough copy paths {: .neutral}
  >
  > The paths mentioned in this option are not relative to the input
  > directory, and instead are relative to the root of the Griffin project.


  ## Ignore files

  Griffin allows users to ignore specific files and/or directories via the
  `--ignore` option. This is useful for ignoring markdown files like readme
  and changelog files that might be in the source directory and that should
  not be processed. A list of comma separated file wildcard paths can be
  passed using this option to ignore files or directories from processing.

  Here's an example:

      $ mix grf.build --ignore=src/posts/drafts,src/README.md

  This command will ignore all input files from the `src/posts/drafts`
  directory along with the `src/README.md` file.
  Wildcard paths are expanded by `Path.wildcard/1` and thus all options that
  it supports can be used to build wildcard paths.

  The paths mentioned in this option are not relative to the input
  directory, and instead are relative to the root of the Griffin project.

  > #### Default ignores {: .neutral}
  >
  > By default Griffin imports the ignores from your `.gitignore` file.


  ## Quiet option

  Griffin prints out information about files that it processed, including the
  rendering engine that processed the file (only `earmark` for now). For large
  projects or other instances where users need minimal console output, there is
  the `--quiet` option.


  ## Config file

  Griffin allows passing in ad-hoc configuration files through the `--config`
  option. This option accepts a path to a file that is then piped into
  `Code.eval_file/2`. Although this file can contain any Elixir code, it is
  expected to return a map with the same configuration keys as those used by
  Application environment. Here's an example `config.ex` file that returns a
  valid Griffin config:

  ```
  %{
    # any other config key could be set here
    input: "custom_input_dir",
    output: "custom_output_dir"
  }
  ```

  This option simplifies configuration since it doesn't rely on Application
  environment, and it allows for better testing.


  ## Dry run

  If you're debugging an issue or just want to test Griffin out, you can use
  the `--dry-run` option to run Griffin without writing to the file system.


  ## Other options

  Griffin uses other configuration options that can be changed by setting
  specific application environment keys under the `:griffin_ssg` application.
  These other options include features that cannot be passed in as a single
  CLI option like hooks, shortcodes, filters, and more.

  ### Hooks

  Hooks are a way to allow user defined functions to be called at specific
  stages of the website generation process. The available hook events
  are:

    - `before`, executed before the build process starts
    - `after`, executed after Griffin finishes building.

  The result from invoking these hooks is not checked.

  Multiple hooks of each kind can be set under
  the `:hooks` configuration key like so:

  ```
  config :griffin_ssg,
    hooks: %{
      before: [
        fn { directories, run_mode, output_mode } ->
          # Read more below about each type of event
          :ok
        end
      ],
      after: [
        fn { directories, results, run_mode, output_mode } ->
          # Read more below about each type of event
          :ok
        end
      ]
    }
  ```

  #### Hook event arguments

  These are the arguments that are passed in to the hook events:

    * `directories`: a map containing the current project directories
        * `directories.input` (defaults to `src`)
        * `directories.output` (defaults to `_site`)
        * `directories.layouts` (defaults to `lib/layouts`)
    * `output_mode`: currently hardcoded to "filesystem"
    * `run_mode`: currently hardcoded to "build"
    * `results`: *(only avaiable on the `after` event)*. A list with the
      processed Griffin output
        * Each individual list item will have
          `{ input_path, output_path, url, content }`

  ### Shortcodes

  Shortcodes are user definable functions that can be invoked inside layouts.
  These functions enable easily reusable content. Shortcodes can be added under
  the `shortcodes` configuration key. Here's an example shortcode for embedding
  YouTube videos:

  ```
  config :griffin_ssg,
    shortcodes: %{
      youtube: fn slug ->
        \"\"\"
        <iframe width="560" height="315" src="https://www.youtube.com/embed/\#{slug}"
                title="YouTube video player" frameborder="0" allow="accelerometer;
                autoplay; clipboard-write; encrypted-media; gyroscope;
                picture-in-picture; web-share" allowfullscreen>
        </iframe>
        \"\"\"
      end
    }
  ```

  This will create a `youtube` assigns variable that can be referenced in
  all layouts like so:

  ```
  <main>
    <p>Here's a classic YouTube video:</p>
    <%= @youtube.("dQw4w9WgXcQ") %>
  </main>
  ```

  Shortcodes can be defined with an arbitrary number of arguments and they are
  expected to return content. They can reference variables or other shortcodes.
  When using shortcodes users can think about them as function components.

  ### Filters

  Filters are utility functions that can be used in layouts to transform and
  data into a more presentable format.

  Like shortcodes, they are set in the application environment and they are
  processed into assigns variables that can be referred in all layouts.

  Here's an example of a layout that uses an `uppercase` filter:

  ```
  <h1><%= @username |> @uppercase.() %></h1>
  ```

  This filter can be defined in the configuration file under the `:filters`
  configuration key:

  ```
  config :griffin_ssg,
    filters: %{
      uppercase: &String.upcase/1
    }
  ```

  > #### Filters versus Shortcodes {: .neutral}
  >
  > Both filters and shortcodes are user defined functions that generate output
  > in some way. While shortcodes are meant to be convenient function
  > components that generate any sort of output, filters are typically designed
  > to be chained, so that the value returned from one filter is piped into the
  > next filter.

  """

  use Mix.Task

  @version Mix.Project.config()[:version]

  @all_options [
    :input,
    :output,
    :layouts,
    :data,
    :passthrough_copies,
    :ignore,
    :config,
    :quiet,
    :dry_run,
    :debug
  ]

  @default_opts %{
    input: "src",
    output: "_site",
    layouts: "lib/layouts",
    data: "data",
    passthrough_copies: [],
    ignore: [],
    hooks: %{
      before: [],
      after: []
    },
    quiet: false,
    dry_run: false,
    # in the future we might support `:watch` and `:serve`
    run_mode: :build,
    # in the future we might support `:json`
    output_mode: :file_system,
    debug: false
  }

  @switches [
    input: :string,
    output: :string,
    layouts: :string,
    data: :string,
    # passthrough copies (comma separated)
    passthrough_copies: :string,
    # ignore files (comma separated)
    ignore: :string,
    # path to config file (to be passed into Code.eval_file)
    config: :string,
    quiet: :boolean,
    dry_run: :boolean,
    debug: :boolean
  ]

  @aliases [
    in: :input,
    out: :output
  ]

  @input_extnames [".md", ".markdown", ".eex"]
  @layout_extnames [".eex"]
  @layouts_max_nesting_level 10

  @impl Mix.Task
  def run(args, _test_opts \\ []) do
    {time_in_microseconds, files_written} =
      :timer.tc(fn ->
        {opts, _parsed} = OptionParser.parse!(args, strict: @switches, aliases: @aliases)

        # Configuration hierarchy:
        # Environment Variables > Command Line Arguments >
        # > Config File > Application Config > Defaults

        opts =
          @default_opts
          |> Map.merge(application_config())
          |> Map.merge(file_config(opts[:config]))
          |> Map.merge(Enum.into(opts, %{}))
          |> Map.merge(environment_config())

        opts = Map.put(opts, :global_assigns, fetch_assigns_from_data_dir(opts))

        directories = %{
          input: opts.input,
          output: opts.output,
          layouts: opts.layouts,
          partials: opts.layouts <> "/partials",
          data: opts.data
        }

        validate_directories!(directories, opts)

        # Call before hooks
        for hook <- opts.hooks.before do
          hook.({directories, opts.run_mode, opts.output_mode})
        end

        copy_passthrough_files!(opts)

        compile_layouts!(opts)

        # subtract ignore files from files list
        ignore_files =
          opts.ignore
          |> maybe_parse_csv()
          |> Enum.flat_map(&GriffinFs.list_all(&1))
          |> Enum.concat(GriffinFs.git_ignores())

        files = GriffinFs.search_directory(opts.input, @input_extnames) -- ignore_files

        # the first stage parses all files, returning metadata that will be used
        # to build collections, which needs to be done before any file is actually
        # rendered

        tasks =
          for file <- files do
            Task.async(__MODULE__, :parse_file, [file, opts])
          end

        parsed_files =
          for task <- tasks do
            Task.await(task, :infinity)
          end

        collections = compile_collections(parsed_files, opts)

        opts = Map.put(opts, :collections, collections)

        tasks =
          for metadata <- parsed_files do
            # TODO consider setting collections globally on ETS
            Task.async(__MODULE__, :render_file, [metadata.output, metadata, opts])
          end

        results =
          for task <- tasks do
            Task.await(task, :infinity)
          end

        # Call after hooks
        for hook <- opts.hooks.after do
          hook.({directories, results, opts.run_mode, opts.output_mode})
        end

        length(results)
      end)

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

  @doc false
  def parse_file(file, config) do
    output_path = config.output
    input_path = config.input

    {:ok, %{front_matter: front_matter, content: content}} = GriffinSSG.parse(File.read!(file))

    file_output_path =
      if Map.has_key?(front_matter, :permalink) do
        output_path <> "/" <> front_matter.permalink <> "/index.html"
      else
        GriffinFs.output_filepath(file, input_path, output_path)
      end

    url =
      file_output_path
      |> String.trim_leading(output_path)
      |> String.trim_trailing("index.html")

    date =
      front_matter
      |> Map.get_lazy(:date, fn ->
        timestamp = File.stat!(file, time: :posix).ctime

        timestamp
        |> DateTime.from_unix!()
        |> DateTime.to_iso8601()
      end)

    %{
      page: %{
        url: url,
        input_path: file,
        output_path: file_output_path,
        date: date
      },
      data: Map.put(front_matter, :url, url),
      content: content,
      input: file,
      output: file_output_path
    }
  end

  @doc false
  def render_file(
        file,
        %{
          page: page,
          data: data,
          content: content,
          input: input_path
        },
        opts
      ) do
    layout_name = Map.get(data, :layout, "__fallback__")

    layout_assigns =
      filters_assigns()
      |> Map.merge(shortcodes_assigns())
      |> Map.merge(partials_assigns())
      |> Map.merge(opts.global_assigns)
      |> Map.merge(%{page: page, collections: opts.collections})
      |> Map.merge(data)
      |> Map.put_new(:title, "Griffin")

    layout = fetch_layout(layout_name)

    if layout == nil do
      Mix.raise("File #{file} specified layout `#{layout_name}` but no such layout was found")
    end

    output =
      GriffinSSG.render(
        layout,
        %{
          content_type: Path.extname(input_path),
          content: content,
          assigns: layout_assigns
        }
      )

    unless opts.quiet do
      Mix.shell().info("writing: #{file} from #{input_path} (markdown)")
    end

    unless opts.dry_run do
      file
      |> Path.dirname()
      |> Path.expand()
      |> File.mkdir_p()

      case File.write(file, output) do
        :ok ->
          :ok

        {:error, reason} ->
          Mix.raise("Unable to write to #{file}: `#{reason}`")
      end
    end

    output
  end

  defp fetch_assigns_from_data_dir(opts) do
    {assigns, num_files} =
      if File.exists?(opts.data) do
        files = GriffinFs.search_directory(opts.data, [".exs"])

        {Enum.reduce(files, %{}, fn file, acc ->
           filename =
             file
             |> Path.basename(Path.extname(file))
             |> String.to_atom()

           {assigns, _} = Code.eval_file(file)
           Map.put(acc, filename, assigns)
         end), length(files)}
      else
        {%{}, 0}
      end

    if opts.debug do
      files_string =
        if num_files == 1 do
          "file"
        else
          "files"
        end

      Mix.shell().info("Stored data in global assigns from #{num_files} #{files_string}")
    end

    assigns
  end

  defp validate_directories!(directories, opts) do
    unless File.exists?(directories.input) do
      Mix.raise("Invalid input directory: `#{directories.input}`")
    end

    unless File.dir?(directories.output) or not File.exists?(directories.output) do
      Mix.raise("Invalid output directory: `#{directories.output}`")
    end

    if opts.debug do
      Mix.shell().info("""
      Directories:
      input: #{directories.input}
      output: #{directories.output}
      layouts: #{directories.layouts}
      """)
    end
  end

  defp copy_passthrough_files!(opts) do
    unless opts.dry_run do
      {elapsed_microseconds, num_files} =
        :timer.tc(fn ->
          opts.passthrough_copies
          |> maybe_parse_csv()
          |> Enum.flat_map(&GriffinFs.list_all(&1))
          |> Enum.map(fn path ->
            # e.g. file 'a/b/c/d.js' will be copied to '<output_dir>/a/b/c/d.js'
            File.mkdir_p(opts.output <> "/" <> Path.dirname(path))
            cp_destination = opts.output <> "/" <> path

            case File.cp(path, cp_destination) do
              :ok ->
                :ok

              {:error, reason} ->
                Mix.raise(
                  "Unable to copy passthrough file from #{path} to #{cp_destination}: `#{reason}`"
                )
            end
          end)
          |> Enum.count()
        end)

      unless opts.quiet do
        files_string =
          if num_files == 1 do
            "file"
          else
            "files"
          end

        microseconds_passed = :erlang.float_to_binary(elapsed_microseconds / 1_000, decimals: 1)

        Mix.shell().info(
          "Copied #{num_files} passthrough #{files_string} in #{microseconds_passed}ms"
        )
      end
    end
  end

  defp compile_collections(parsed_files, opts) do
    collections =
      parsed_files
      |> Enum.filter(fn metadata ->
        metadata.data[:tags] != nil
      end)
      |> Enum.reduce(%{}, fn metadata, acc ->
        metadata_tags = metadata.data.tags

        tags =
          if is_list(metadata_tags) do
            metadata_tags
          else
            # single tag
            [metadata_tags]
          end

        Enum.reduce(tags, acc, fn tag, current_tags ->
          Map.update(current_tags, String.to_atom(tag), [metadata], fn list_files ->
            [metadata | list_files]
          end)
        end)
      end)

    if opts.debug do
      Mix.shell().info("Collections: #{Enum.join(Map.keys(collections), ", ")}")

      for {tag, files} <- collections do
        files_pretty_print =
          files
          |> Enum.map(fn metadata -> metadata.input end)
          |> Enum.join(",")

        Mix.shell().info("Collection #{tag}: #{files_pretty_print}")
      end
    end

    collections
  end

  defp compile_layouts!(opts) do
    try do
      :ets.new(:griffin_build_layouts, [:ordered_set, :public, :named_table])
      :ets.new(:griffin_build_layout_strings, [:ordered_set, :public, :named_table])
    rescue
      ArgumentError ->
        :ok
    end

    layouts_dir = opts.layouts
    layout_partials_dir = layouts_dir <> "/partials"

    layout_files = GriffinFs.search_directory(layouts_dir, @layout_extnames)
    layout_names = Enum.map(layout_files, &Path.basename(&1, Path.extname(&1)))
    num_layouts = length(layout_files)

    result =
      Enum.reduce_while(1..@layouts_max_nesting_level, layout_files, fn pass, acc ->
        case compile_layouts_rec(acc, layout_names) do
          :ok ->
            {:halt, :ok}

          not_compiled when pass < @layouts_max_nesting_level ->
            {:cont, not_compiled}

          not_compiled ->
            {:halt, {:error, :partial_failure, not_compiled}}
        end
      end)

    case result do
      :ok ->
        :ok

      {:error, :partial_failure, not_compiled} ->
        errored_layouts =
          not_compiled
          |> Enum.map(&Path.basename(&1, Path.extname(&1)))
          |> Enum.sort()
          |> Enum.join(", ")

        Mix.raise("Dependency issue with layouts `[#{errored_layouts}]`")
    end

    partial_layouts = GriffinFs.search_directory(layout_partials_dir, @layout_extnames)
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

    unless opts.quiet do
      Mix.shell().info(
        "Compiled #{num_layouts + num_partials} layouts (#{num_partials} partial#{unless num_partials == 1, do: "s"})"
      )
    end

    # compile fallback layout
    insert_layout("__fallback__", fallback_html_layout())

    :ok
  end

  defp compile_layouts_rec(layouts, not_compiled \\ [], layout_names)

  defp compile_layouts_rec([], [], _layout_names), do: :ok
  defp compile_layouts_rec([], not_compiled, _layout_names), do: not_compiled

  defp compile_layouts_rec([file | remaining], acc, layout_names) do
    layout_name = Path.basename(file, Path.extname(file))

    layout =
      file
      |> File.read!()
      |> GriffinSSG.parse()
      |> then(fn {:ok, result} -> result end)

    case maybe_compile_layout(layout, layout_name, layout_names) do
      {:error, :parent_layout_not_found} ->
        compile_layouts_rec(remaining, [file | acc], layout_names)

      :ok ->
        compile_layouts_rec(remaining, acc, layout_names)
    end
  end

  defp maybe_compile_layout(%{front_matter: front_matter, content: content}, name, all_layouts) do
    if front_matter[:layout] == nil do
      # layout has no parent
      insert_layout(name, content)
      insert_layout_string(name, content)
      :ok
    else
      parent = front_matter.layout

      unless parent in all_layouts do
        Mix.raise(
          "Layout #{name} specified parent layout `#{parent}` but no such layout was found"
        )
      end

      parent_layout = fetch_layout_string(parent)

      if parent_layout == nil do
        {:error, :parent_layout_not_found}
      else
        # there is currently no better way of doing this that I know of,
        # since compiled or eval'ed EEx strings replace all variables
        # and we only want to replace @content.
        # This isn't ideal because users might use different spacing
        # which wouldn't work with the way we're merging the layouts.
        content_patterns = [
          "<%= @content %>",
          "<%=@content%>",
          "<%=@content %>",
          "<%= @content%>"
        ]

        pattern =
          Enum.reduce(content_patterns, "<%= @content %>", fn pattern, acc ->
            if String.contains?(parent_layout, pattern) do
              pattern
            else
              acc
            end
          end)

        merged_content = String.replace(parent_layout, pattern, content)
        insert_layout(name, merged_content)
        insert_layout_string(name, merged_content)
        :ok
      end
    end
  end

  defp insert_layout(name, string) do
    ets_insert(:griffin_build_layouts, name, EEx.compile_string(string))
  end

  defp insert_layout_string(name, string) do
    ets_insert(:griffin_build_layout_strings, name, string)
  end

  defp fetch_layout_string(name) do
    ets_lookup(:griffin_build_layout_strings, name)
  end

  defp fetch_layout(name) do
    ets_lookup(:griffin_build_layouts, name)
  end

  defp ets_insert(table, key, value) do
    :ets.insert(table, {key, value})
  end

  defp ets_lookup(table, key) do
    case :ets.lookup(table, key) do
      [] -> nil
      [{^key, value}] -> value
    end
  end

  defp maybe_parse_csv(value) when is_binary(value) do
    String.split(value, ",")
  end

  defp maybe_parse_csv(value), do: value

  defp application_config do
    @all_options
    |> Enum.map(fn option -> {option, get_app_env(option)} end)
    |> Enum.into(%{})
    |> Map.filter(fn {_, v} -> not is_nil(v) end)
  end

  defp file_config(nil), do: %{}

  defp file_config(config_file) do
    {config, _} = Code.eval_file(config_file)

    if is_map(config) do
      config
    else
      %{}
    end
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

  defp partials_assigns() do
    :griffin_build_layouts
    |> :ets.lookup(:__partials__)
    |> then(fn [{:__partials__, partials}] ->
      %{partials: partials}
    end)
  end

  defp filters_assigns() do
    Map.merge(default_filters(), get_app_env(:filters, %{}))
  end

  defp default_filters() do
    %{
      uppercase: &String.upcase/1,
      lowercase: &String.downcase/1
    }
  end

  defp shortcodes_assigns() do
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
      </head>
      <body>
      <%= @content %>
      </body>
    </html>
    """
  end
end
