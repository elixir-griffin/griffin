defmodule Griffin.YamlTest do
  use ExUnit.Case

  test "it reads frontmatter data properly" do
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
