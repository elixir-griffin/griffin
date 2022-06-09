defmodule Mix.Tasks.Local.Grf do
  use Mix.Task

  @shortdoc "Updates the Griffin project generator locally"

  @moduledoc """
  Updates the Griffin project generator locally.
      $ mix local.grf
  Accepts the same command line options as `archive.install hex grf_new`.
  """

  @impl true
  def run(args) do
    Mix.Task.run("archive.install", ["hex", "grf_new" | args])
  end
end
