defmodule GriffinSSG do
  @moduledoc """
  Griffin is a Static Site Generator.

  Griffin reads Markdown files from disk and outputs HTML pages. A combination
  of Application level config, frontmatter attributes and layout files can be
  used to customize the output of each file and to build the page structure of
  the website.

  Each input file can have a first segment called "front matter" that lists
  metadata about the file contents. This front matter segment is delineated by
  a sequence of characters `---` and the contents should be in YAML format.
  The contents that follow can contain plain content or reference front matter
  attributes.
  Here is an example of a short Markdown file with some front matter attributes:

  ```
  ---
  title: "Griffin Static Site Generator"
  draft: true
  ---

  # Griffin Static Site Generator
  Griffin is an Elixir framework for building static websites.
  ```

  """

  alias GriffinSSG.Filesystem

  @doc """
  Parses a file at the given path into two components: front matter and file content.
  """
  def parse(file_path, input_path, output_path) do
    {:ok, %{front_matter: front_matter, content: content}} = parse_string(File.read!(file_path))

    file_output_path =
      if Map.has_key?(front_matter, :permalink) do
        Path.join([output_path, front_matter.permalink, "index.html"])
      else
        Filesystem.output_filepath(file_path, input_path, output_path)
      end

    url =
      file_output_path
      |> String.trim_leading(output_path)
      |> String.trim_trailing("index.html")

    date =
      Map.get_lazy(front_matter, :date, fn ->
        timestamp = File.stat!(file_path, time: :posix).ctime

        timestamp
        |> DateTime.from_unix!()
        |> DateTime.to_iso8601()
      end)

    %{
      page: %{
        url: url,
        title: Map.get(front_matter, :title),
        description: Map.get(front_matter, :description),
        input_path: file_path,
        output_path: file_output_path,
        date: date
      },
      data: Map.put(front_matter, :url, url),
      content: content,
      input: file_path,
      output: file_output_path
    }
  end

  @doc """
  Parses the string contents of a file into two components: front matter and file content.

  Front matter is an optional YAML snippet containing variables to be used in the content.
  The content immediately follows the front matter and may reference front matter variables.

  Returns `{:ok, map()}` where map contains both the front matter and file content.
  """
  def parse_string(string_content) do
    {front_matter, content} =
      case String.split(string_content, ~r/\n---\n/, parts: 2) do
        [content] ->
          {%{}, content}

        [raw_frontmatter, content] ->
          {parse_frontmatter(raw_frontmatter), content}
      end

    {:ok, %{front_matter: front_matter, content: content}}
  rescue
    MatchError ->
      {:error, :parsing_front_matter_failed}
  end

  @doc """
  Renders a layout with a given content, front matter and assigns.

  The layout is assumed to be a compiled EEx file or string, such that calling
  `Code.eval_quoted/2` on the layout will generate a correct result.
  """
  def render(layout, options) do
    assigns = Map.get(options, :assigns, %{})
    rerender_partials = Map.get(options, :rerender_partials, true)

    content =
      options
      |> Map.fetch!(:content)
      |> EEx.eval_string(assigns: assigns)
      |> then(fn content_string ->
        case Map.get(options, :content_type, ".md") do
          md when md in [".md", ".markdown"] ->
            Earmark.as_html!(content_string)

          ".eex" ->
            content_string
        end
      end)

    layout_assigns =
      assigns
      |> Map.put(:content, content)
      # here we're re-rendering all existing partials when we might only need a very small subset.
      # refactor: render only required partials by looking at args in the quoted expression for `layout`
      |> then(fn current_assigns ->
        if rerender_partials do
          Map.update(current_assigns, :partials, %{}, fn partials ->
            # refactor: reduce nesting level by pulling parts into separate functions.
            # credo:disable-for-lines:3
            Map.new(partials, fn partial ->
              {compiled, _bindings} = Code.eval_quoted(partial, assigns: current_assigns)
              compiled
            end)
          end)
        else
          current_assigns
        end
      end)
      |> Enum.to_list()

    {result, _bindings} = Code.eval_quoted(layout, assigns: layout_assigns)
    result
  end

  @doc """
  Lists all pages in a directory, returning metadata about each page.
  The directory page is relative to the project root.
  """
  def list_pages(parsed_files, directory, opts \\ []) do
    parsed_files
    |> Enum.filter(fn file ->
      file_inside_directory?(file.page.input_path, directory)
    end)
    # optional filter
    |> then(fn files ->
      case Keyword.get(opts, :filter) do
        nil ->
          files

        filter ->
          Enum.filter(files, fn file ->
            filter.(file.data)
          end)
      end
    end)
    # optional sort
    |> then(fn files ->
      case Keyword.get(opts, :sort_by) do
        nil ->
          files

        :date ->
          # date sort defaults to descending order
          sorter = {Keyword.get(opts, :sort_order, :desc), DateTime}
          Enum.sort_by(files, &get_page_datetime/1, sorter)

        sort ->
          Enum.sort_by(files, sort, Keyword.get(opts, :sort_order, :asc))
      end
    end)
  end

  defp parse_frontmatter(yaml) do
    {:ok, [parsed]} = YamlElixir.read_all_from_string(yaml, atoms: true)

    Map.new(parsed, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp file_inside_directory?(file, directory) do
    directory = Path.expand(directory)

    directory_path =
      if String.ends_with?(directory, "/") do
        directory
      else
        "#{directory}/"
      end

    String.starts_with?(Path.expand(file), directory_path)
  end

  defp get_page_datetime(page) do
    datetime = Map.get(page.data, :date, "")

    case DateTime.from_iso8601(datetime) do
      {:error, _} ->
        # make posts without date appear at the end when using the default descending sort
        DateTime.from_unix!(0)

      {:ok, datetime, _} ->
        datetime
    end
  end
end
