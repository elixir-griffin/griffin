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

      assert content =~ "Getting started"
    end

    test "renders front matter variables before html output" do
      assert {:ok, %{content: content}} =
               GriffinSSG.parse("""
               ---
               fruit: 🍊
               meal: 🍝
               place: 🌊
               ---
               My favorite fruit is the <%= @fruit %>.
               My favorite meal is <%= @meal %>.
               My favorite place is the <%= @place %>.
               """)

      assert content =~ "My favorite fruit is the 🍊."
      assert content =~ "My favorite meal is 🍝."
      assert content =~ "My favorite place is the 🌊."
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
end
