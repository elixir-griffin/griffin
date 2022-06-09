defmodule Grf.New.Project do
  @moduledoc false
  defstruct [:app_name, :module, :path, :version]

  @version Mix.Project.config()[:version]

  def new(opts) do
    %__MODULE__{
      app_name: to_app_name(opts[:module] || Keyword.fetch!(opts, :app_name)),
      module: to_module_name(opts[:module] || opts[:app_name]),
      path: ensure_path(opts[:path] || "./#{opts[:app_name]}"),
      version: @version
    }
  end

  defp ensure_path(path) do
    if String.ends_with?(path, "/") do
      path
    else
      path <> "/"
    end
  end

  defp to_app_name(name) do
    String.downcase(name)
  end

  defp to_module_name(name) do
    name
    |> String.split(["-", "_"], trim: true)
    |> Stream.map(&upcase_first_letter/1)
    |> Enum.join("")
  end

  defp upcase_first_letter(<<head::utf8, tail::binary>>) do
    String.upcase(<<head::utf8>>) <> tail
  end
end
