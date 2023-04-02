defmodule GriffinFs do
  @moduledoc """
  Helper functions for handling files and paths
  """

  @ignored_dirs [".git", ".elixir_ls"]

  @doc """
  Lists all files from a path or wildcard.
  If `filepath` is a path to a file, returns a list with only that filepath.
  If `filepath` points to a directory, returns a list of all files inside
  that directory and subdirectories.
  A list of ignored paths can be passed in to `opts`. The default value for
  `opts` is `[".git", ".elixir_ls"]`
  """
  def list_all(filepath, opts \\ @ignored_dirs) do
    if String.contains?(filepath, "*") do
      # wildcard path, expand manually
      filepath
      |> Path.wildcard()
      |> Enum.reject(&File.dir?(&1))
    else
      list_all_rec(filepath, opts)
    end
  end

  @doc """
  Searches a given path for files that have the selected extensions
  """
  def search_directory(path, extensions) do
    path
    |> list_all()
    |> Enum.filter(&(Path.extname(&1) in extensions))
  end

  @doc """
  Calculates the output path for a file.
  The `filepath` is a contained within `input_dir`, which means that to
  calculate the filepath in the output directory we need to see what is
  the filepath relative to the `input_dir`. The end result is a concatenation
  of the `output_dir` with this relative path.
  """
  def output_filepath(filepath, input_dir, output_dir) do
    dirname =
      case Path.dirname(Path.relative_to(filepath, input_dir)) do
        "." ->
          "/"

        path ->
          "/" <> path <> "/"
      end

    filename =
      case Path.basename(filepath, Path.extname(filepath)) do
        "index" ->
          "index.html"

        name ->
          name <> "/index.html"
      end

    output_dir <> dirname <> filename
  end

  def git_ignores(path \\ ".gitignore") do
    if File.exists?(path) do
      path
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(fn line ->
        not String.starts_with?(line, "#") and line !== ""
      end)
      |> Enum.map(fn file -> String.trim(file, "/") end)
    else
      []
    end
  end

  defp list_all_rec(filepath, ignore_list) do
    if String.contains?(filepath, ignore_list) do
      []
    else
      case File.ls(filepath) do
        {:ok, files} ->
          Enum.flat_map(files, &list_all_rec("#{filepath}/#{&1}", ignore_list))

        {:error, _} ->
          # file path resolves to single file
          [filepath]
      end
    end
  end
end
