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

  @doc """
  Parses the string contents of a file into two components: front matter and file content.

  Front matter is an optional YAML snippet containing variables to be used in the content.
  The content immediately follows the front matter and may reference front matter variables.

  Returns `{:ok, map()}` where map contains both the front matter and file content.
  """
  def parse(string_content, _opts \\ []) do
    try do
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
            partials
            |> Enum.map(fn partial ->
              {compiled, _bindings} = Code.eval_quoted(partial, assigns: current_assigns)
              compiled
            end)
            |> Enum.into(%{})
          end)
        else
          current_assigns
        end
      end)
      |> Enum.to_list()

    {result, _bindings} = Code.eval_quoted(layout, assigns: layout_assigns)
    result
  end

  defp parse_frontmatter(yaml) do
    {:ok, [parsed]} = YamlElixir.read_all_from_string(yaml, atoms: true)

    parsed
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end
end
