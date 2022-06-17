defmodule GriffinSSGTest do
  use ExUnit.Case, async: true

  describe "parse_file/2" do
    test "parses files into {frontmatter, content} format" do
      assert {frontmatter, content} = GriffinSSG.parse_file("test/files/post.md")

      assert frontmatter.title == "Griffin Static Site Generator"
      assert frontmatter.date == "2022-06-14T10:01:55.506374Z"
      assert frontmatter.draft == false

      refute content == ""
      assert content =~ "Getting started"
    end

    test "can parse files that only contain frontmatter" do
      assert {frontmatter, content} = GriffinSSG.parse_file("test/files/frontmatter-only.md")

      assert frontmatter.title == "Griffin Static Site Generator -- Frontmatter only file"
      assert frontmatter.date == "2022-06-14T09:45:55.506374Z"
      assert frontmatter.draft == false

      assert content == ""
    end

    test "can parse files that only contain content" do
      assert {frontmatter, content} = GriffinSSG.parse_file("test/files/content-only.md")

      assert frontmatter == nil

      assert content =~ "Content Only"
    end
  end

  describe "compile_layout/2" do
    test "generates quoted code that can be evaluated into something valid" do
      assert quoted = EEx.compile_file("test/files/simple-layout.html.eex")

      assert quoted ==
               {:__block__, [],
                [
                  {:=, [],
                   [
                     {:arg0, [], EEx.Engine},
                     {{:., [], [{:__aliases__, [alias: false], [:String, :Chars]}, :to_string]},
                      [],
                      [
                        {{:., [line: 1],
                          [
                            {:__aliases__, [line: 1, alias: false], [:EEx, :Engine]},
                            :fetch_assign!
                          ]}, [line: 1],
                         [
                           {:var!, [line: 1, context: EEx.Engine, import: Kernel],
                            [{:assigns, [line: 1], EEx.Engine}]},
                           :title
                         ]}
                      ]}
                   ]},
                  {:=, [],
                   [
                     {:arg1, [], EEx.Engine},
                     {{:., [], [{:__aliases__, [alias: false], [:String, :Chars]}, :to_string]},
                      [],
                      [
                        {{:., [line: 1],
                          [
                            {:__aliases__, [line: 1, alias: false], [:EEx, :Engine]},
                            :fetch_assign!
                          ]}, [line: 1],
                         [
                           {:var!, [line: 1, context: EEx.Engine, import: Kernel],
                            [{:assigns, [line: 1], EEx.Engine}]},
                           :content
                         ]}
                      ]}
                   ]},
                  {:<<>>, [],
                   [
                     "<html><title>",
                     {:"::", [], [{:arg0, [], EEx.Engine}, {:binary, [], EEx.Engine}]},
                     "</title><body>",
                     {:"::", [], [{:arg1, [], EEx.Engine}, {:binary, [], EEx.Engine}]},
                     "</body></html>"
                   ]}
                ]}

      assert {eval, _bindings} =
               Code.eval_quoted(quoted, assigns: [content: "Griffin", title: "test file"])

      assert eval == "<html><title>test file</title><body>Griffin</body></html>"
    end
  end

  describe "render/3" do
    test "writes a rendered layout file to disk" do
      tmp_path = Path.expand("test-data/output.html", __DIR__)

      assert layout = GriffinSSG.compile_layout("test/files/simple-layout.html.eex")
      assert {frontmatter, content} = GriffinSSG.parse_file("test/files/post.md")

      refute File.exists?(tmp_path)

      File.mkdir_p!(Path.dirname(tmp_path))

      assert :ok = GriffinSSG.render(tmp_path, layout, frontmatter: frontmatter, content: content)
      assert File.exists?(tmp_path)

      assert file = File.read!(tmp_path)
      assert file =~ "<title>Griffin Static Site Generator</title>"
      assert file =~ "Griffin is a framework for building static sites"

      File.rm!(tmp_path)
      File.rmdir!(Path.dirname(tmp_path))
    end
  end
end
