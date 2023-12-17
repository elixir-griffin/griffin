defmodule GriffinSSG.Plugin.Collections do
  @moduledoc """
  The Collections plugin is responsible for creating collections of pages.
  A typical example is a blog, where you want to create a collection of all
  blog posts posts tagged with a certain tag.

  Currently this doesn't work with multiple running tests due to using the
  global config. This should be fixed by making init return a config that is
  passed into the hooks.
  """
  @behaviour GriffinSSG.Plugin.Behaviour

  alias GriffinSSG.Layouts

  @impl true
  def init(_config, opts) do
    collections_config = Keyword.get(opts, :collections)
    unless is_nil(collections_config) do
      GriffinSSG.Config.put(:collections_config, collections_config)

      GriffinSSG.Config.register_hook(:post_parse, &__MODULE__.compile_collections/1)
      GriffinSSG.Config.register_hook(:after, &__MODULE__.run/1)
      |> dbg()
    end
    :ok
  end

  def compile_collections({_, parsed_files, _, _}) do
    dbg("oink")
    opts = GriffinSSG.Config.get()
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

    GriffinSSG.Config.put(:collections, collections)
  end

  def run({_, results, _, _}) do
    dbg("neigh")
    config = GriffinSSG.Config.get()

    render_collections_pages(config.collections, config)
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
