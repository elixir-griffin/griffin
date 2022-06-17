defmodule GriffinSSG do
  @moduledoc """
  This is the documentation for the Griffin project.

  By default, Griffin will scan for content in the `priv/content` directory
  and output generated files to the `_site` directory.

  Griffin depends on the following libraries:

    * [Plug](https://hexdocs.pm/plug) - a specification and conveniences
      for composable modules in between web applications
  """

  use Application

  @doc false
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: GriffinSSG.Web.Plug, options: [port: 4000]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Griffin.Supervisor)
  end

  @doc """
  Reads a file from disk and returns
  the parsed frontmatter metadata and the file contents.
  """
  def parse_file(path, _options \\ []) do
    file_content = File.read!(path)

    # split file contents into frontmatter metadata and content
    [frontmatter, content] =
      case String.split(file_content, ~r/\n---\n/, parts: 2) do
        [content] ->
          [nil, content]

        [raw_frontmatter, content] ->
          [parse_frontmatter(raw_frontmatter), parse_content(content)]
      end

    {frontmatter, content}
  end

  @doc """
  Compiles a template file from disk into quoted code
  that can then be used by `GriffinSSG.render/3`.
  """
  def compile_layout(path, _options \\ []) do
    EEx.compile_file(path)
  end

  @doc """
  Renders a layout to file, taking in a number of options that affect the rendered output.

  The following `options` are accepted:

    * `frontmatter`   - the frontmatter attributes
    * `content`       - the content to render in the layout
    * `assigns`       - a map with template variables to be used in the layout
  """
  def render(path, layout, options) do
    frontmatter = Keyword.fetch!(options, :frontmatter)
    content = Keyword.fetch!(options, :content)
    assigns = Keyword.get(options, :assigns, %{})

    flat_assigns =
      frontmatter
      |> Map.put(:content, content)
      |> Map.merge(assigns)
      # here we're compiling all existing partials when we might only need a very small subset.
      # TODO compile only required partials by looking at args in the quoted expression
      |> then(fn current_assigns ->
        Map.update!(current_assigns, :partials, fn partials ->
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
    File.write!(path, result)
  end

  @doc false
  def process_file(path) do
    IO.inspect("reading from #{path}")
    content = File.read!(path)
    # string split crashes if the file only contains html and
    # does not contain front matter annotations.
    [yaml, markdown] = String.split(content, ~r/\n---\n/, parts: 2)
    [metadata] = YamlElixir.read_all_from_string!(yaml, atoms: true)
    html = Earmark.as_html!(markdown)
    IO.inspect(html)

    metadata =
      metadata
      |> Map.put("content", html)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> IO.inspect(label: "metadata")

    # IO.inspect(html, label: "html")
    rendered = EEx.eval_file("installer/blog/priv/layouts/default.html.eex", assigns: metadata)

    unless html == "" do
      output_path = Path.expand("#{path}.html")
      IO.inspect("writing to #{output_path}")
      File.write!(output_path, rendered)
    end

    :ok
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
