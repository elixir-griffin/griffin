defmodule GriffinYamlTest do
  use ExUnit.Case, async: true

  test "parses front matter YAML properly" do
    yaml = """
      title: "Griffin Static Site Generator"
      date: "2022-06-08T12:37:55.506374Z"
      draft: true
    """

    assert %{
             "title" => "Griffin Static Site Generator",
             "date" => "2022-06-08T12:37:55.506374Z",
             "draft" => true
           } = YamlElixir.read_from_string!(yaml)
  end

  test "doesn't crash when given empty input" do
    assert %{} = YamlElixir.read_from_string!("")
  end
end
