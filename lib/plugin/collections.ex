defmodule GriffinSSG.Plugin.Collections do
  @moduledoc """
  The Collections plugin is responsible for creating collections of pages.
  A typical example is a blog, where you want to create a collection of all
  blog posts posts tagged with a certain tag.
  """
  @behaviour GriffinSSG.Plugin.Behaviour

  use GenServer

  alias GriffinSSG.Layouts

  @collection_config_opts [:permalink, :list_layout, :show_layout]

  # GriffinSSG.Plugin callbacks

  @impl true
  def start_link(griffin_config, plugin_opts) do
    name = Keyword.get(plugin_opts, :name, nil)
    process_opts = if name != nil, do: [name: name], else: []

    GenServer.start_link(
      __MODULE__,
      %{griffin_config: griffin_config, opts: plugin_opts},
      process_opts
    )
  end

  @impl true
  def list_hooks() do
    %{
      before: [],
      post_parse: [&__MODULE__.compile_collections/1],
      after: [&__MODULE__.render_collection_pages/1]
    }
  end

  # Griffin callbacks
  def compile_collections(pid \\ __MODULE__, {_, parsed_files, _, _}) do
    GenServer.call(pid, {:compile_collections, parsed_files})
  end

  def render_collection_pages(pid \\ __MODULE__, {_, _results, _, _}) do
    GenServer.call(pid, :render_collection_pages)
  end

  # GenServer callbacks

  @impl true
  def init(%{griffin_config: griffin_config, opts: plugin_opts}) do
    case validate_config(plugin_opts) do
      {:ok, config} ->
        {:ok, %{griffin_config: griffin_config, opts: config}}

      {:error, _msg} = error ->
        error
    end
  end

  @impl true
  def handle_call(
        {:compile_collections, parsed_files},
        _from,
        %{griffin_config: griffin_config, opts: opts} = state
      ) do
    collections =
      opts
      |> Enum.map(fn {collection_name, config} ->
        # refactor: terrible efficiency, we're traversing the parsed list files
        # once per collection. Since most sites will have 1-2 collections max,
        # we're fine with this for now.
        {collection_name,
         compile_collection(collection_name, parsed_files, Map.merge(griffin_config, config))}
      end)
      |> Enum.into(%{})

    {:reply, :ok, Map.put(state, :collections, collections)}
  end

  def handle_call(
        :render_collection_pages,
        _from,
        %{collections: collections, griffin_config: griffin_config} = state
      ) do
    result = do_render_collections_pages(collections, griffin_config)

    {:reply, result, state}
  end

  # internal functions

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
      is_number(arg) -> "number"
      is_atom(arg) -> "atom"
      is_binary(arg) -> "binary"
      is_list(arg) -> "list"
      is_tuple(arg) -> "tuple"
      true -> to_string(arg)
    end
  end

  defp valid_collection?(config) do
    Enum.all?(@collection_config_opts, fn opt ->
      is_binary(Map.get(config, opt))
    end)
  end

  defp do_render_collections_pages(collections, _opts) when collections == %{}, do: :ok

  defp do_render_collections_pages(collections, opts) do
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
