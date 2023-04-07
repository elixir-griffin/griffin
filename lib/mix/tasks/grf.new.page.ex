defmodule Mix.Tasks.Grf.New.Page do
  use Mix.Task

  @shortdoc "Generates a new Markdown content page"

  @moduledoc """
  Generates a new Markdown page with relevant front matter attributes.

      $ mix grf.gen.page [--title TITLE] [--draft] PATH

  A Markdown file will be created with the name at the specified path
  with the default metadata fields: `title`, `date` and `draft`.

  ## Options
    * `--title` - the title parameter in the frontmatter.
      Defaults to the filename.

    * `--draft` - marks the file as a draft in the frontmatter.
  """

  @switches [
    title: :string,
    draft: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, path} = OptionParser.parse!(args, strict: @switches)

    opts = Enum.into(opts, %{})

    path
    |> Path.dirname()
    |> File.mkdir_p!()

    title = opts[:title] || path
    draft = opts[:draft] || false
    date = DateTime.utc_now() |> DateTime.to_iso8601()

    File.write!(path, """
    ---
    title: "#{title}"
    date: "#{date}"
    draft: #{draft}
    ---
    """)

    Mix.shell().info("* creating #{path}")
  end

  # def run(_) do
  #   Mix.raise(
  #     "Unprocessable arguments, please use `mix help grf.gen.page` for documentation on correct usage"
  #   )
  # end
end
