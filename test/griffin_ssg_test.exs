defmodule GriffinSSGTest do
  use ExUnit.Case, async: true

  describe "parse/1" do
    test "parses files with frontmatter and content" do
      assert {:ok, %{front_matter: frontmatter, content: content}} =
               GriffinSSG.parse("""
               ---
               title: "Griffin Static Site Generator"
               date: "2022-06-14T10:01:55.506374Z"
               draft: false
               ---

               # Griffin Static Site Generator
               Griffin is a framework for building static sites inspired by [11ty](https://www.11ty.dev/),
               [Hugo](https://gohugo.io/) and others. It's purposely made to feel familiar to Elixir and Phoenix users.

               ## Getting started
               Install the latest version of Griffin by following the latest instructions on the hex.pm
               [package page](https://hexdocs.pm/griffin_ssg/installation.html#griffin)
               """)

      assert frontmatter.title == "Griffin Static Site Generator"
      assert frontmatter.date == "2022-06-14T10:01:55.506374Z"
      assert frontmatter.draft == false

      refute content == ""
      assert content =~ "Getting started"
    end

    test "parses files that only contain frontmatter" do
      assert {:ok, %{front_matter: frontmatter, content: content}} =
               GriffinSSG.parse("""
               ---
               title: "Griffin Static Site Generator -- Frontmatter only file"
               date: "2022-06-14T09:45:55.506374Z"
               draft: false
               ---
               """)

      assert frontmatter.title == "Griffin Static Site Generator -- Frontmatter only file"
      assert frontmatter.date == "2022-06-14T09:45:55.506374Z"
      assert frontmatter.draft == false

      assert content == ""
    end

    test "parses files that only contain content" do
      assert {:ok, %{front_matter: frontmatter, content: content}} =
               GriffinSSG.parse("""
               # Content Only
               This is a test file containing markdown only.
               """)

      assert frontmatter == %{}

      assert content =~ "Content Only"
    end
  end

  # describe "compile_layout/2" do
  #   test "generates quoted code that can be evaluated into something valid" do
  #     assert quoted = EEx.compile_file("test/files/layouts/simple.html.eex")

  #     assert {eval, _bindings} =
  #              Code.eval_quoted(quoted, assigns: [content: "Griffin", title: "test file"])

  #     assert eval == "<html><title>test file</title><body>Griffin</body></html>"
  #   end
  # end

  # describe "render/3" do
  #   test "writes a rendered layout file to disk" do
  #     tmp_path = Path.expand("test-data/output.html", __DIR__)

  #     assert layout = EEx.compile_file("test/files/layouts/simple.html.eex")
  #     assert {:ok, {frontmatter, content}} = GriffinSSG.parse_file("test/files/post.md")

  #     refute File.exists?(tmp_path)

  #     File.mkdir_p!(Path.dirname(tmp_path))

  #     assert :ok = GriffinSSG.render(tmp_path, layout, frontmatter: frontmatter, content: content)
  #     assert File.exists?(tmp_path)

  #     assert file = File.read!(tmp_path)
  #     assert file =~ "<title>Griffin Static Site Generator</title>"
  #     assert file =~ "Griffin is a framework for building static sites"

  #     File.rm!(tmp_path)
  #     File.rmdir!(Path.dirname(tmp_path))
  #   end
  # end
end
