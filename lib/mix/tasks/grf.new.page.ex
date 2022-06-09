defmodule Mix.Tasks.Grf.New.Page do
  use Mix.Task

  @shortdoc "Generates a new Markdown content page"

  @moduledoc """
  Generates a new Markdown page with relevant front matter attributes.

      $ mix grf.gen.page PATH [--title TITLE]

  A Markdown file will be created with the name at the specified path
  with the default metadata fields: `title`, `date` and `draft`.

  ## Options
    * `--title` - the page title.
      Defaults to `_site`
  """

  @impl Mix.Task
  def run([name]) do
    title = name
    current_date = DateTime.utc_now() |> DateTime.to_iso8601()
    directory = Path.expand(name) |> Path.dirname()
    File.mkdir_p!(directory)

    File.write!(Path.expand("./#{name}"), """
    ---
    title: "#{title}"
    date: "#{current_date}"
    draft: true
    ---
    """)

    Mix.shell().info("* creating #{name}")
  end

  def run(_) do
    Mix.raise(
      "Unprocessable arguments, please use `mix help grf.gen.page` for documentation on correct usage"
    )
  end
end
