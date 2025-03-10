defmodule GriffinSSGTest do
  use ExUnit.Case, async: true

  describe "list_pages/1" do
    setup do
      input_path = "test/support/files"
      output_path = "test/support/files"

      test_files = [
        "test/support/files/post.md",
        "test/support/files/content-only.md",
        "test/support/files/frontmatter-only.md",
        # yes, we duplicate the same file here
        "test/support/files/post.md"
      ]

      parsed_files =
        Enum.map(test_files, fn file -> GriffinSSG.parse(file, input_path, output_path) end)

      [parsed_files: parsed_files]
    end

    test "correctly lists out all pages in a directory with files", %{parsed_files: parsed_files} do
      pages = GriffinSSG.list_pages(parsed_files, "test/support/files")

      assert 4 == length(pages)

      # check that paths are set on all pages returned
      refute Enum.any?(pages, fn page -> is_nil(page.page[:output_path]) end)
      refute Enum.any?(pages, fn page -> is_nil(page.page[:input_path]) end)

      # check that the path is relative to the root directory
      assert Enum.all?(pages, fn page -> String.starts_with?(page.page.output_path, "test/support/files/") end)
    end

    test "returns an empty list with a directory where none of the parsed files were from", %{parsed_files: parsed_files} do
      assert Enum.empty?(GriffinSSG.list_pages(parsed_files, "lib"))
    end

    test "returns an empty list with an invalid path", %{parsed_files: parsed_files} do
      assert Enum.empty?(GriffinSSG.list_pages(parsed_files, "/404/directory-not-found"))
    end

    test "can filter pages within the given directory", %{parsed_files: parsed_files} do
      # one of the 4 test files has no frontmatter, so we can filter it out
      filter_fn = fn frontmatter -> Map.get(frontmatter, :draft) == false end

      pages =
        GriffinSSG.list_pages(parsed_files, "test/support/files", filter: filter_fn)

      assert 3 == length(pages)
    end

    test "can sort pages by date", %{parsed_files: parsed_files} do
      # filter by posts with date set
      filter_fn = fn frontmatter -> Map.has_key?(frontmatter, :date) end

      # sort by date, default descending order
      pages =
        GriffinSSG.list_pages(parsed_files, "test/support/files", filter: filter_fn, sort_by: :date, sort_order: :desc)

      assert 3 == length(pages)

      page_dates =
        Enum.map(pages, fn page ->
          {:ok, date, _} = DateTime.from_iso8601(page.data.date)
          date
        end)

      assert page_dates == Enum.sort(page_dates, {:desc, DateTime})

      # sort by date, ascending
      pages =
        GriffinSSG.list_pages(parsed_files, "test/support/files", filter: filter_fn, sort_by: :date, sort_order: :asc)

      page_dates =
        Enum.map(pages, fn page ->
          {:ok, date, _} = DateTime.from_iso8601(page.data.date)
          date
        end)

      assert page_dates == Enum.sort(page_dates, {:asc, DateTime})

      # sort by date, descending
      pages =
        GriffinSSG.list_pages(parsed_files, "test/support/files", filter: filter_fn, sort_by: :date, sort_order: :desc)

      page_dates =
        Enum.map(pages, fn page ->
          {:ok, date, _} = DateTime.from_iso8601(page.data.date)
          date
        end)

      assert page_dates == Enum.sort(page_dates, {:desc, DateTime})
    end

    test "can sort by other fields", %{parsed_files: parsed_files} do
      # sort by title, ascending
      pages =
        GriffinSSG.list_pages(parsed_files, "test/support/files",
          filter: fn frontmatter -> Map.has_key?(frontmatter, :title) end,
          sort_by: &Map.get(&1.data, :title),
          sort_order: :asc
        )

      # one of the files has no title, so it should be filtered out
      assert 3 == length(pages)

      page_titles = Enum.map(pages, fn page -> page.data.title end)

      assert page_titles == Enum.sort(page_titles, :asc)

      # sort by title, descending
      pages =
        GriffinSSG.list_pages(parsed_files, "test/support/files",
          filter: fn frontmatter -> Map.has_key?(frontmatter, :title) end,
          sort_by: &Map.get(&1.data, :title),
          sort_order: :desc
        )

      page_titles = Enum.map(pages, fn page -> page.data.title end)

      assert page_titles == Enum.sort(page_titles, :desc)
    end
  end

  describe "parse/2" do
    @tag :skip
    test "parses a valid file and fills in path" do
      assert {:ok, %{front_matter: frontmatter, content: content, path: path}} =
               GriffinSSG.parse("test/support/files/post.md")

      assert frontmatter.title == "Griffin Static Site Generator"
      assert frontmatter.date == "2022-06-14T10:01:55.506374Z"
      assert frontmatter.draft == false

      assert content =~ "Griffin Static Site Generator"
      assert content =~ "Griffin is a framework for building static sites"

      assert path == "test/support/files/post.md"
    end

    @tag :skip
    test "parses a valid file and fills in relative path" do
      assert {:ok, %{front_matter: frontmatter, content: content, path: path}} =
               GriffinSSG.parse("test/support/files/post.md", from_root_directory: "test/support")

      assert frontmatter.title == "Griffin Static Site Generator"
      assert frontmatter.date == "2022-06-14T10:01:55.506374Z"
      assert frontmatter.draft == false

      assert content =~ "Griffin Static Site Generator"
      assert content =~ "Griffin is a framework for building static sites"

      assert path == "files/post.md"
    end
  end

  describe "parse_string/2" do
    test "parses files with frontmatter and content" do
      assert {:ok, %{front_matter: frontmatter, content: content}} =
               GriffinSSG.parse_string("""
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
               GriffinSSG.parse_string("""
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
               GriffinSSG.parse_string("""
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
        EEx.compile_string("""
        <main>
        <p><%= @phrase %></p>
        <%= for thing <- @things do %>
          <p>I like <%= thing %>.</p>
        <% end %>
        <%= @content %>
        </main>
        """)

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

      layout = EEx.compile_string("<main><%= @content %></main>")

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

      layout = EEx.compile_string("<main><%= @content %></main>")

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

      layout = EEx.compile_string("<main><%= @content %></main>")

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
