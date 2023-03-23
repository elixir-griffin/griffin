defmodule GriffinYamlTest do
  use ExUnit.Case, async: true

  test "it prases front matter YAML properly" do
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
end
