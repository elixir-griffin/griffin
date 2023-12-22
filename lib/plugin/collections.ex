defmodule GriffinSSG.Plugin.Collections do
  @moduledoc """
  The Collections plugin is responsible for creating collections of pages.
  A typical example is a blog, where you want to create a collection of all
  blog posts posts tagged with a certain tag.
  """
  @behaviour GriffinSSG.Plugin.Behaviour

  alias GriffinSSG.Layouts

  @collection_config_opts [:permalink, :list_layout, :show_layout]

  @impl true
  def init(_opts, plugin_opts) do
    case validate_config(plugin_opts) do
      {:ok, config} ->
        config =
          if Enum.empty?(config) do
            config
          else
            %{
              state: config,
              hooks: %{
                post_parse: [&__MODULE__.compile_collections/1],
                after: [&__MODULE__.run/1]
              }
            }
          end

        {:ok, config}

      error ->
        error
    end
  end

  def compile_collections({_, parsed_files, _, _}) do
    opts = GriffinSSG.Config.get_all()

    collections =
      opts.collections_config
      |> Enum.map(fn {collection_name, config} ->
        # refactor: terrible efficiency, we're traversing the parsed list files
        # once per collection. Since most sites will have 1-2 collections max,
        # we're fine with this for now.
        {collection_name,
         compile_collection(collection_name, parsed_files, Map.merge(opts, config))}
      end)
      |> Enum.into(%{})
  end

  def run({_, _results, _, _}, config) do
    render_collections_pages(config.collections, config)
  end

  defp validate_config(plugin_opts) do
    config = Keyword.get(plugin_opts, :collections, %{})

    Enum.reduce_while(config, {:ok, config}, fn {collection, config}, acc ->
      cond do
        not is_atom(collection) ->
          {:halt,
           {:error, "expected an atom as the collection name, found #{typeof(collection)}"}}

        not is_map(config) ->
          {:halt,
           {:error,
            "expected a map as the config for collection `#{collection}`, found #{typeof(config)}"}}

        not valid_collection?(config) ->
          {:halt,
           {:error, "config for collection `#{collection}` is invalid, check all required opts"}}

        true ->
          {:cont, acc}
      end
    end)
  end

  def typeof(arg) do
    cond do
      is_map(arg) -> "map"
      is_float(arg) -> "float"
      is_number(arg) -> "number"
      is_atom(arg) -> "atom"
      is_boolean(arg) -> "boolean"
      is_binary(arg) -> "binary"
      is_function(arg) -> "function"
      is_list(arg) -> "list"
      is_tuple(arg) -> "tuple"
      true -> "unknown"
    end
  end

  defp valid_collection?(config) do
    Enum.all?(@collection_config_opts, fn opt ->
      is_binary(Map.get(config, opt))
    end)
  end

  defp render_collections_pages(collections, _opts) when collections == %{}, do: :ok

  defp render_collections_pages(collections, opts) do
    # Generate collections pages (example of tags below):
    # render `/tags/` page listing all tags
    # render `/tags/:tag` page listing all pages with that tag
    for {collection_name, collection_values} <- collections do
      render_collection_file(
        opts.output_path <> "/#{collection_name}/index.html",
        %{
          page: nil,
          data: %{
            layout: EEx.compile_string(Layouts.fallback_list_collection_layout()),
            collection_name: collection_name,
            collection_values: collection_values
          },
          content: "",
          input: "tags_list.eex"
        },
        opts
      )

      for {collection_value, collection_value_pages} <- collection_values do
        collection_value = collection_value |> Atom.to_string() |> Slug.slugify()

        render_collection_file(
          opts.output <> "/#{collection_name}/#{collection_value}/index.html",
          %{
            page: nil,
            data: %{
              layout: EEx.compile_string(Layouts.fallback_show_collection_layout()),
              collection_name: collection_name,
              collection_value: collection_value,
              collection_value_pages: collection_value_pages
            },
            content: "",
            input: "tags.eex"
          },
          opts
        )
      end
    end
  end

  # refactor: this function shares much of the logic of render_file.
  @doc false
  def render_collection_file(
        file,
        %{
          page: page,
          data: data,
          content: content,
          input: input_path
        },
        opts
      ) do
    layout = Map.fetch!(data, :layout)

    layout_assigns =
      opts.global_assigns
      |> Map.merge(%{page: page, collections: opts.collections})
      |> Map.merge(data)
      |> Map.put_new(:title, "Griffin")

    output =
      GriffinSSG.render(
        layout,
        %{
          content_type: Path.extname(input_path),
          content: content,
          assigns: layout_assigns,
          rerender_partials: false
        }
      )

    unless opts.quiet do
      Mix.shell().info("writing: #{file}")
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

  defp compile_collection(collection_name, parsed_files, opts) do
    collections =
      parsed_files
      |> Enum.filter(fn metadata ->
        metadata.data[collection_name] != nil
      end)
      |> Enum.reduce(%{}, fn metadata, acc ->
        collection_values = metadata.data[collection_name]

        values =
          if is_list(collection_values) do
            collection_values
          else
            # single value
            [collection_values]
          end

        Enum.reduce(values, acc, fn value, current_values ->
          Map.update(current_values, String.to_atom(value), [metadata], fn list_files ->
            [metadata | list_files]
          end)
        end)
      end)

    if Map.get(opts, :debug, true) do
      string_col_name = String.capitalize(Atom.to_string(collection_name))
      collections_pretty_print = Enum.join(Map.keys(collections), ", ")
      Mix.shell().info("#{string_col_name}: #{collections_pretty_print}")

      for {value, files} <- collections do
        files_pretty_print = Enum.map_join(files, ",", fn metadata -> metadata.input end)

        Mix.shell().info("#{string_col_name} #{value}: #{files_pretty_print}")
      end
    end

    collections
  end
end
