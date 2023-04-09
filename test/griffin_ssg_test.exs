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
               Griffin is a framework for building static sites.
               """)

      assert frontmatter.title == "Griffin Static Site Generator"
      assert frontmatter.date == "2022-06-14T10:01:55.506374Z"
      assert frontmatter.draft == false

      assert content =~ "Griffin Static Site Generator"
      assert content =~ "Griffin is a framework for building static sites."
    end

    test "parses files that only contain frontmatter" do
      assert {:ok, %{front_matter: frontmatter, content: content}} =
               GriffinSSG.parse("""
               ---
               title: "Griffin -- Frontmatter only file"
               date: "2022-06-14T09:45:55.506374Z"
               draft: false
               ---
               """)

      assert frontmatter.title == "Griffin -- Frontmatter only file"
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

  describe "render/2" do
    test "renders layout variables from assigns map" do
      layout =
        """
        <main>
        <p><%= @phrase %></p>
        <%= for thing <- @things do %>
          <p>I like <%= thing %>.</p>
        <% end %>
        <%= @content %>
        </main>
        """
        |> EEx.compile_string()

      output =
        GriffinSSG.render(layout, %{
          content: "I am some content",
          assigns: %{
            phrase: "Here's what I care about:",
            things: [
              "Cake",
              "Chocolate",
              "Cookies"
            ]
          }
        })

      assert output =~ "<p>Here's what I care about:</p>"
      assert output =~ "<p>I like Cake.</p>"
      assert output =~ "<p>I like Chocolate.</p>"
      assert output =~ "<p>I like Cookies.</p>"
      assert output =~ "I am some content"
    end

    test "renders basic layouts when content type is markdown" do
      content_input = """
      # Title
      Markdown is a cool format
      """

      layout =
        "<main><%= @content %></main>"
        |> EEx.compile_string()

      output =
        GriffinSSG.render(layout, %{
          content_type: ".md",
          content: content_input,
          assigns: %{foo: "Here is the content"}
        })

      assert output =~ "Title</h1>"
      assert output =~ "Markdown is a cool format"
    end

    test "renders basic layouts when content type is eex" do
      content_input = """
      <h1>Title</h1>
      <p>Markdown is a cool format</p>
      """

      layout =
        "<main><%= @content %></main>"
        |> EEx.compile_string()

      output =
        GriffinSSG.render(layout, %{
          content_type: ".eex",
          content: content_input
        })

      assert output == "<main>#{content_input}</main>"
    end

    test "renders variables in content when content type is eex" do
      content_input = """
      <p><%= @foo %></p>
      <h1>Title</h1>
      <p>Markdown is a cool format</p>
      """

      layout =
        "<main><%= @content %></main>"
        |> EEx.compile_string()

      output =
        GriffinSSG.render(layout, %{
          content_type: ".eex",
          content: content_input,
          assigns: %{foo: "Here is the content"}
        })

      assert output =~ "<p>Here is the content</p>"
      assert output =~ "<h1>Title</h1>"
      assert output =~ "Markdown is a cool format"
    end
  end
end
