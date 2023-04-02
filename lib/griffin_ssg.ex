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
  Renders a layout with a given content, front matter and assigns.

  The layout is assumed to be a compiled EEx file or string, such that calling
  `Code.eval_quoted/2` on the layout will generate a correct result.
  """
  def render(layout, options) do
    content = Map.fetch!(options, :content)
    assigns = Map.get(options, :assigns, %{})

    flat_assigns =
      assigns
      |> Map.put(:content, content)
      # here we're compiling all existing partials when we might only need a very small subset.
      # TODO compile only required partials by looking at args in the quoted expression
      |> then(fn current_assigns ->
        Map.update(current_assigns, :partials, %{}, fn partials ->
          partials
          |> Enum.map(fn partial ->
            {compiled, _bindings} = Code.eval_quoted(partial, assigns: current_assigns)
            compiled
          end)
          |> Enum.into(%{})
        end)
      end)
      |> Enum.to_list()

    {result, _bindings} = Code.eval_quoted(layout, assigns: flat_assigns)
    result
  end

  @doc """
  Parses the string contents of a file into two components: front matter and file content.

  Front matter is optional metadata about the content that is defined at the top of the file.
  The content immediately follows the front matter and may reference front matter variables.

  Returns a map with both the front matter and file content.
  """
  def parse(string_content) do
    try do
      {front_matter, content} =
        case String.split(string_content, ~r/\n---\n/, parts: 2) do
          [content] ->
            {%{}, parse_content(content)}

          [raw_frontmatter, content] ->
            {parse_frontmatter(raw_frontmatter), parse_content(content)}
        end

      {:ok, %{front_matter: front_matter, content: content}}
    rescue
      MatchError ->
        {:error, :parsing_front_matter_failed}
    end
  end

  defp parse_frontmatter(yaml) do
    {:ok, [parsed]} = YamlElixir.read_all_from_string(yaml, atoms: true)

    parsed
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  defp parse_content(content) do
    Earmark.as_html!(content)
  end
end
