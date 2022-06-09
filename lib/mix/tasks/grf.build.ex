defmodule Mix.Tasks.Grf.Build do
  use Mix.Task

  @shortdoc "Generates a static website with Griffin"

  @moduledoc """
  Generates a Griffin static site from existing template files

      $ mix grf.build

  A set of files will be written to the configured output directory,
  `_site` by default
  """

  @impl Mix.Task
  def run([]) do
    Mix.shell().info("hello")
  end

  def run(_) do
    Mix.raise(
      "Unprocessable arguments, please use `mix help grf.build` for documentation on correct usage"
    )
  end
end
