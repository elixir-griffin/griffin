defmodule GriffinSSG.File.ParserTest do
  use ExUnit.Case, async: true

  alias GriffinSSG.File.Parser
  alias GriffinSSG.ContentFile

  describe "from_string/1" do
    test "works with a simple text file" do
      string = """
      This is just a text file.

      It has multiple lines
      """

      assert {:ok, %ContentFile{front_matter: %{}, content: string}} ==
               Parser.from_string(string)
    end

    test "works with a front matter only file" do
      title = "front matter only file"
      date = "2023-12-19T22:00:55.506374Z"
      draft = true

      string = """
      ---
      title: #{title}
      date: #{date}
      draft: #{draft}
      ---
      """

      assert {:ok, %ContentFile{front_matter: front_matter, content: ""}} =
               Parser.from_string(string)

      assert title == front_matter.title
      assert date == front_matter.date
      assert draft == front_matter.draft
    end

    test "works on a markdown file with front matter" do
      title = "markdown with front matter"
      date = "2023-12-19T22:00:55.506374Z"
      draft = false

      string = """
      ---
      title: #{title}
      date: #{date}
      draft: #{draft}
      ---
      # This is a heading
      ## This is a smaller heading
      ### This is an even smaller heading
      #### This is the smallest heading
      This is normal text

      - This is a bullet list
      - This is another item

      More normal text

      1- This is an ordered list
      2- This is number two

      [this is a link](http://example.com)
      """

      assert {:ok, %ContentFile{front_matter: front_matter, content: content}} =
               Parser.from_string(string)

      assert title == front_matter.title
      assert date == front_matter.date
      assert draft == front_matter.draft

      lines =
        string
        |> String.split("\n", trim: true)
        # drop front matter which is 5 lines
        |> Enum.drop(5)

      for line <- lines do
        assert content =~ line
      end
    end

    test "works on a markdown file with tables, no front matter" do
      string = """
      # This is a Markdown table
      | Tables   |      Are      |  Cool |
      |----------|:-------------:|------:|
      | col 1 is |  left-aligned | $1600 |
      | col 2 is |    centered   |   $12 |
      | col 3 is | right-aligned |    $1 |

      ## Brief pause
      | Tables   |      Are      |  Cool |
      |----------|:-------------:|------:|
      | col 1 is |  left-aligned | $1600 |
      | col 2 is |    centered   |   $12 |
      | col 3 is | right-aligned |    $1 |
      """

      assert {:ok, %ContentFile{front_matter: %{}, content: content}} =
               Parser.from_string(string)

      lines = String.split(string, "\n", trim: true)

      for line <- lines do
        assert content =~ line
      end
    end

    test "works on a markdown file with tables and front matter" do
      title = "markdown with front matter"
      date = "2023-12-19T22:00:55.506374Z"
      draft = false

      string = """
      ---
      title: #{title}
      date: #{date}
      draft: #{draft}
      ---
      # This is a Markdown table
      | Tables   |      Are      |  Cool |
      |----------|:-------------:|------:|
      | col 1 is |  left-aligned | $1600 |
      | col 2 is |    centered   |   $12 |
      | col 3 is | right-aligned |    $1 |

      ## Brief pause
      | Tables   |      Are      |  Cool |
      |----------|:-------------:|------:|
      | col 1 is |  left-aligned | $1600 |
      | col 2 is |    centered   |   $12 |
      | col 3 is | right-aligned |    $1 |
      """

      assert {:ok, %ContentFile{front_matter: front_matter, content: content}} =
               Parser.from_string(string)

      assert title == front_matter.title
      assert date == front_matter.date
      assert draft == front_matter.draft

      lines =
        string
        |> String.split("\n", trim: true)
        # drop front matter which is 5 lines
        |> Enum.drop(5)

      for line <- lines do
        assert content =~ line
      end
    end
  end
end
