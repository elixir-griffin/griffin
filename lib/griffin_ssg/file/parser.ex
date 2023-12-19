defmodule GriffinSSG.File.Parser do
  @moduledoc """
  Module responsible for parsing files into GriffinSSG.File structs.
  """
  alias GriffinSSG.ContentFile

  def from_string(string_content) do
    try do
      {front_matter, content} =
        case String.split(string_content, ~r/---\n/, trim: true) do
          [binary] ->
            if is_nil(Regex.run(~r/---\n/, string_content)) do
              # content only file
              {%{}, binary}
            else
              # front matter only file
              {parse_frontmatter(binary), ""}
            end

          [raw_frontmatter, content] ->
            {parse_frontmatter(raw_frontmatter), content}
        end

      {:ok, %ContentFile{front_matter: front_matter, content: content}}
    rescue
      MatchError ->
        {:error, :parsing_front_matter_failed}
    end
  end

  def from_file(filepath) do
    case File.read(filepath) do
      {:ok, file} ->
        from_string(file)

      error ->
        error
    end
  end

  defp parse_frontmatter(yaml) do
    {:ok, [parsed]} = YamlElixir.read_all_from_string(yaml, atoms: true)

    parsed
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end
end
