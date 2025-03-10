defmodule Mix.Tasks.Grf.BuildTest do
  use ExUnit.Case, async: false

  import Assertions, only: [assert_lists_equal: 2]
  import GriffinFileHelper

  # Missing tests:
  # - config hierarchy
  # - nested shortcodes
  # - not rendering files that have draft in front matter

  alias Mix.Tasks.Grf.Build

  @tag :tmp_dir
  test "doesn't work on any files when given an empty input directory", %{tmp_dir: tmp_dir} do
    Build.run(["--input", tmp_dir, "--output", Path.join(tmp_dir, "/_site")])
    assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
  end

  @tag :tmp_dir
  test "raises when input directory isn't a readable directory", %{tmp_dir: tmp_dir} do
    assert_raise Mix.Error, "Invalid input directory: `#{Path.join(tmp_dir, "404")}`", fn ->
      Build.run(["--input", Path.join(tmp_dir, "404")])
    end
  end

  @tag :tmp_dir
  test "raises when output directory isn't a writeable directory", %{tmp_dir: tmp_dir} do
    corrupt_directory = Path.join(tmp_dir, "/output")
    File.write!(Path.join(tmp_dir, "/output"), "abc123")

    assert_raise Mix.Error, "Invalid output directory: `#{corrupt_directory}`", fn ->
      Build.run(["--input", tmp_dir, "--output", corrupt_directory])
    end
  end

  @tag :tmp_dir
  test "files are output to the same relative directory as the input directory", %{
    tmp_dir: tmp_dir
  } do
    File.mkdir_p!(Path.join(tmp_dir, "/a/b/c"))

    File.write!(Path.join(tmp_dir, "/a/b/c/d.md"), """
    # Testing output
    This is supposed to go to <output>/a/b/c/d/index.html
    """)

    Build.run(["--input", tmp_dir, "--output", tmp_dir])
    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
    assert_file(Path.join(tmp_dir, "/a/b/c/d/index.html"))
  end

  @tag :tmp_dir
  test "input files with name `index` get written to the same relative directory", %{
    tmp_dir: tmp_dir
  } do
    File.mkdir_p!(Path.join(tmp_dir, "/a/b/c"))

    File.write!(Path.join(tmp_dir, "/a/b/c/index.md"), """
    # Testing output
    Since this is an index file,
    the output is supposed to go to <output>/a/b/c/index.html
    """)

    Build.run(["--input", tmp_dir, "--output", tmp_dir])
    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
    assert_file(Path.join(tmp_dir, "/a/b/c/index.html"))
  end

  @tag :tmp_dir
  test "one layout can include multiple partials", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/a.md"), """
    ---
    title: "A"
    foo: "Foo"
    bar: "Bar"
    baz: "Baz"
    layout: "a"
    ---
    # File A
    this is file A
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/layouts/partials"))

    File.write!(Path.join(tmp_dir, "/layouts/a.eex"), """
    <html><title><%= @title %></title><body>
    <%= @partials.one %>
    <%= @partials.two %>
    <%= @content %>
    <%= @partials.three %>
    </body></html>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/partials/one.eex"), """
    <div id="one"><%= @foo %></div>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/partials/two.eex"), """
    <div id="two"><%= @bar %></div>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/partials/three.eex"), """
    <div id="three"><%= @baz %></div>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/layouts")
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/a/index.html"), fn file ->
      assert file =~ "<div id=\"one\">"
      assert file =~ "Foo"
      assert file =~ "<div id=\"two\">"
      assert file =~ "Bar"
      assert file =~ "File A"
      assert file =~ "this is file A"
      assert file =~ "<div id=\"three\">"
      assert file =~ "Baz"
    end)
  end

  @tag :tmp_dir
  test "can render multiple different layouts", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/a.md"), """
    ---
    title: "A"
    layout: "a"
    ---
    # File A
    this is file A
    """)

    File.write!(Path.join(tmp_dir, "/src/b.md"), """
    ---
    title: "B"
    layout: "b"
    ---
    # File B
    this is file B
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/layouts"))

    File.write!(Path.join(tmp_dir, "/layouts/a.eex"), """
    <html><title><%= @title %></title><body><div id="a"><%= @content%></div></body></html>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/b.eex"), """
    <html><title><%= @title %></title><body><div id="b"><%= @content%></div></body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/layouts")
    ])

    assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/a/index.html"), fn file ->
      assert file =~ "<div id=\"a\">"
      assert file =~ "File A"
      refute file =~ "<div id=\"b\">"
      refute file =~ "File B"
    end)

    assert_file(Path.join(tmp_dir, "/b/index.html"), fn file ->
      assert file =~ "<div id=\"b\">"
      assert file =~ "File B"
      refute file =~ "<div id=\"a\">"
      refute file =~ "File A"
    end)
  end

  @tag :tmp_dir
  test "can render nested layouts with assigns", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/a.md"), """
    ---
    title: "Nested Layouts"
    layout: "e"
    ---
    # Nesting layouts
    how to lose the joy of life in one simple feature
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/layouts"))

    File.write!(Path.join(tmp_dir, "/layouts/a.eex"), """
    <html><title><%= @title %></title><body><div id="a"><%= @content %></div></body></html>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/b.eex"), """
    ---
    layout: "a"
    language: Elixir
    ---
    <h1>Griffin Times</h1>
    <%= @content%>
    """)

    # lets reference a frontmatter variable from the parent layout
    File.write!(Path.join(tmp_dir, "/layouts/c.eex"), """
    ---
    layout: "b"
    ---
    <h2><%= @language %> News</h2>
    <%= @content%>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/d.eex"), """
    ---
    layout: "c"
    ---
    <h3>Releases</h3>
    <%= @content%>
    """)

    # lets reference a frontmatter variable from layouts `b` and from `e` itself
    File.write!(Path.join(tmp_dir, "/layouts/e.eex"), """
    ---
    layout: "d"
    latest_elixir: 1.18
    ---
    <h4><%= @language %> version <%= @latest_elixir %></h4>
    <%= @content%>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/layouts"),
      "--debug"
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
    assert_received {:mix_shell, :info, ["Compiled 5 layouts (0 partials)"]}

    assert_file(Path.join(tmp_dir, "/a/index.html"), fn file ->
      assert file =~ "<title>Nested Layouts"
      assert file =~ "<div id=\"a\">"
      assert file =~ "<h1>Griffin Times"
      assert file =~ "<h2>Elixir News"
      assert file =~ "<h3>Releases"
      assert file =~ "<h4>Elixir version 1.18"
      assert file =~ "Nesting layouts"
      assert file =~ "how to lose the joy of life in one simple feature"
    end)
  end

  @tag :tmp_dir
  test "pages without a layout use the fallback HTML layout", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "/a.md"), """
    # File A
    this is file A
    """)

    Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/a/index.html"), fn file ->
      assert file =~ "<!DOCTYPE html>"

      assert file =~
               ~s(<meta name="viewport" content="width=device-width, initial-scale=1.0">)

      assert file =~ "this is file A"
    end)
  end

  @tag :tmp_dir
  test "raises when there are ciclic dependencies between layouts", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/layouts"))

    File.write!(Path.join(tmp_dir, "/layouts/a.eex"), """
    ---
    layout: "b"
    ---
    <h1>Griffin Times</h1>
    <%= @content%>
    """)

    File.write!(Path.join(tmp_dir, "/layouts/b.eex"), """
    ---
    layout: "a"
    ---
    <h2>Elixir News</h2>
    <%= @content%>
    """)

    assert_raise Mix.Error, "Dependency issue with layouts `[a, b]`", fn ->
      Build.run([
        "--input",
        tmp_dir,
        "--output",
        tmp_dir,
        "--layouts",
        Path.join(tmp_dir, "/layouts")
      ])
    end
  end

  @tag :tmp_dir
  test "front matter is reflected in the final output of the file", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "/d.md"), """
    ---
    title: "My custom title"
    ---
    # Testing output
    The HTML page is supposed to have a title defined
    from the front matter.
    """)

    Build.run(["--input", tmp_dir, "--output", tmp_dir])
    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/d/index.html"), fn file ->
      assert file =~ "<title>My custom title</title>"
    end)
  end

  @tag :tmp_dir
  test "front matter variables can be used inside templates", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "/d.md"), """
    ---
    sum: 4
    result: 3
    ---
    # Quick Maths
    2 plus 2 is <%= @sum %> minus 1 is <%= @result %>
    """)

    Build.run(["--input", tmp_dir, "--output", tmp_dir])
    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/d/index.html"), fn file ->
      assert file =~ "2 plus 2 is 4 minus 1 is 3"
    end)
  end

  @tag :tmp_dir
  test "pages with permalinks get written to the right directory", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "/a.md"), """
    ---
    title: "A"
    permalink: "alpha/delta/gamma/some-custom-page"
    ---
    # File A
    this is file A
    """)

    File.write!(Path.join(tmp_dir, "/b.md"), """
    ---
    title: "B"
    permalink: "beta"
    ---
    # File B
    this is file B
    """)

    Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir
    ])

    assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/alpha/delta/gamma/some-custom-page/index.html"), fn file ->
      assert file =~ "this is file A"
    end)

    assert_file(Path.join(tmp_dir, "/beta/index.html"), fn file ->
      assert file =~ "this is file B"
    end)
  end

  @tag :tmp_dir
  test "passthrough copies files to the correct path", %{tmp_dir: tmp_dir} do
    Build.run([
      "--input",
      tmp_dir,
      "--output",
      Path.join(tmp_dir, "/_site"),
      "--passthrough-copies",
      # this is copying from the root of the project
      "priv/**/*.ico,logo.png",
      "--debug"
    ])

    assert_received {:mix_shell, :info, ["Copied 2 passthrough files in " <> _]}

    assert_file(Path.join(tmp_dir, "/_site/priv/static/favicon.ico"))
    assert_file(Path.join(tmp_dir, "/_site/logo.png"))
  end

  @tag :tmp_dir
  test "calls hooks before and after executing", %{tmp_dir: tmp_dir} do
    config_file = File.read!("test/support/files/config/hooks_only.ex")

    File.mkdir_p!(tmp_dir)
    :ok = File.write(Path.join(tmp_dir, "/config.ex"), config_file)

    Build.run([
      "--input",
      tmp_dir,
      "--config",
      Path.join(tmp_dir, "/config.ex")
    ])

    assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
    assert_received {:mix_shell, :info, ["I was called before build: " <> timestamp_before]}
    assert_received {:mix_shell, :info, ["Directories before: " <> directories_before]}
    assert_received {:mix_shell, :info, ["Run mode before: build"]}
    assert_received {:mix_shell, :info, ["Output mode before: file_system"]}
    assert_received {:mix_shell, :info, ["Directories after: " <> directories_after]}
    assert_received {:mix_shell, :info, ["Results after: []"]}
    assert_received {:mix_shell, :info, ["Run mode after: build"]}
    assert_received {:mix_shell, :info, ["Output mode after: file_system"]}
    assert_received {:mix_shell, :info, ["I was called after build: " <> timestamp_after]}

    directories = %{
      input: tmp_dir,
      output: "_site",
      layouts: "lib/layouts",
      partials: "lib/layouts/partials",
      data: "data"
    }

    expected_directories = "#{inspect(directories)}"

    assert directories_before == expected_directories
    assert directories_after == expected_directories
    assert timestamp_before <= timestamp_after
  end

  @tag :tmp_dir
  test "ignores files specified via CLI arguments", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/process/other"))
    File.mkdir_p!(Path.join(tmp_dir, "/ignore/some"))

    File.write!(Path.join(tmp_dir, "/ignore/some/file.md"), """
    # This won't be processed
    """)

    File.write!(Path.join(tmp_dir, "/process/other/file.md"), """
    # But this will
    """)

    Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir,
      "--ignore",
      Path.join(tmp_dir, "/ignore/**")
    ])

    refute_file(Path.join(tmp_dir, "/ignore/some/file/index.html"))

    assert_file(Path.join(tmp_dir, "/process/other/file/index.html"), fn file ->
      assert file =~ "But this will"
    end)

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
  end

  @tag :tmp_dir
  test "filters can be used in layouts correctly", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/a.md"), """
    ---
    title: "title"
    layout: "a"
    ---
    # griffin filters
    this will be uppercase
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/layouts"))

    # use the default uppercase filter
    File.write!(Path.join(tmp_dir, "/layouts/a.eex"), """
    <html><title><%= @title %></title>
    <body>
    <%= @content |> @uppercase.() %>
    <hr />
    </body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/layouts")
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/a/index.html"), fn file ->
      assert file =~ "GRIFFIN FILTERS"
      assert file =~ "THIS WILL BE UPPERCASE"
    end)
  end

  @tag :tmp_dir
  test "shortcodes can be used in layouts correctly", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/a.md"), """
    ---
    title: "title"
    video_slug: "dQw4w9WgXcQ"
    layout: "a"
    ---
    # Cool video
    This is a cool video you should watch
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/layouts"))

    # use the default shortcode for youtube videos
    File.write!(Path.join(tmp_dir, "/layouts/a.eex"), """
    <html><title><%= @title %></title>
    <body>
    <%= @content %>
    <hr />
    <%= @youtube.(@video_slug) %>
    </body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/layouts")
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/a/index.html"), fn file ->
      assert file =~ "This is a cool video you should watch"
      assert file =~ "src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\""
    end)
  end

  @tag :tmp_dir
  test "a config file can be passed in to configure Griffin", %{tmp_dir: tmp_dir} do
    config_file = """
    %{
      input: \"#{Path.join(tmp_dir, "/source")}\",
      output: \"#{Path.join(tmp_dir, "/public")}\",
      layouts: \"#{Path.join(tmp_dir, "/cooldesignsinc")}\"
    }
    """

    File.mkdir_p!(tmp_dir)
    :ok = File.write(Path.join(tmp_dir, "/config.ex"), config_file)

    File.mkdir_p!(Path.join(tmp_dir, "/source"))

    File.write!(Path.join(tmp_dir, "/source/file.md"), """
    ---
    layout: "conf"
    ---
    # Config is tricky
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/cooldesignsinc"))

    File.write!(Path.join(tmp_dir, "/cooldesignsinc/conf.eex"), """
    <html><body><div id="config-test"><%= @content %></div></body></html>
    """)

    Build.run(["--config", Path.join(tmp_dir, "/config.ex")])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/public/file/index.html"), fn file ->
      assert file =~ "<div id=\"config-test\">"
      assert file =~ "Config is tricky"
    end)
  end

  @tag :tmp_dir
  test "quiet option has intended effect", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(tmp_dir)

    File.write!(Path.join(tmp_dir, "/one.md"), """
    # one
    """)

    File.write!(Path.join(tmp_dir, "/two.md"), """
    # two
    """)

    Build.run(["--input", tmp_dir, "--output", tmp_dir, "--quiet"])

    assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}
    refute_received {:mix_shell, :info, ["Compiled 0 layouts (0 partials)"]}
    refute_received {:mix_shell, :info, ["writing: " <> _]}

    assert_file(Path.join(tmp_dir, "/one/index.html"))
    assert_file(Path.join(tmp_dir, "/two/index.html"))
  end

  @tag :tmp_dir
  test "dry run option prevents writing to the file system", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/process/some"))
    File.mkdir_p!(Path.join(tmp_dir, "/process/other"))

    File.write!(Path.join(tmp_dir, "/process/some/file.md"), """
    # This won't be written to file system
    """)

    File.write!(Path.join(tmp_dir, "/process/other/file.md"), """
    # Neither will this
    """)

    Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir,
      "--passthrough-copies",
      "priv/static",
      "--dry-run"
    ])

    # this message might change in the future
    assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}

    # neither passthrough nor markdown files were actually written
    refute_file(Path.join(tmp_dir, "/priv/static/favicon.ico"))
    refute_file(Path.join(tmp_dir, "/priv/static/griffin.png"))

    refute_file(Path.join(tmp_dir, "/process/some/file/index.html"))
    refute_file(Path.join(tmp_dir, "/process/other/file/index.html"))
  end

  @tag :tmp_dir
  test "collections are generated correctly", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/config.exs"), """
    %{
      collections: %{
        tags: %{}
      }
    }
    """)

    File.write!(Path.join(tmp_dir, "/src/notags.md"), """
    ---
    title: "no tags"
    ---
    # I have no tags
    """)

    File.write!(Path.join(tmp_dir, "/src/onetag.md"), """
    ---
    title: "one tag"
    tags: "post"
    ---
    # I have one tag
    """)

    File.write!(Path.join(tmp_dir, "/src/moretags.md"), """
    ---
    title: more tags
    tags:
      - post
      - personal
      - tldr
    ---
    # I have three tags
    """)

    File.write!(Path.join(tmp_dir, "/src/evenmore.md"), """
    ---
    title: even more tags
    tags: ["personal"]
    ---
    # I also have tags but in different yaml
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      Path.join(tmp_dir, "/_site"),
      "--config",
      Path.join(tmp_dir, "/config.exs"),
      "--debug"
    ])

    assert_file(Path.join(tmp_dir, "/_site/notags/index.html"))
    assert_file(Path.join(tmp_dir, "/_site/onetag/index.html"))
    assert_file(Path.join(tmp_dir, "/_site/moretags/index.html"))
    assert_file(Path.join(tmp_dir, "/_site/evenmore/index.html"))

    assert_received {:mix_shell, :info, ["Wrote 4 files in " <> _]}
    # assert_received {:mix_shell, :info, ["Collections: personal, post, tldr"]}
    assert_received {:mix_shell, :info, ["Tags personal: " <> personal_tagged_csv]}
    assert_received {:mix_shell, :info, ["Tags post: " <> post_tagged_csv]}
    assert_received {:mix_shell, :info, ["Tags tldr: " <> tldr_tagged_csv]}

    one_tag_file = Path.absname(Path.join(tmp_dir, "/src/onetag.md"))
    more_tags_file = Path.absname(Path.join(tmp_dir, "/src/moretags.md"))
    even_more_file = Path.absname(Path.join(tmp_dir, "/src/evenmore.md"))

    personal_collection = String.split(personal_tagged_csv, ",")
    post_collection = String.split(post_tagged_csv, ",")
    tldr_collection = String.split(tldr_tagged_csv, ",")

    assert_lists_equal(personal_collection, [more_tags_file, even_more_file])
    assert_lists_equal(post_collection, [one_tag_file, more_tags_file])
    assert_lists_equal(tldr_collection, [more_tags_file])
  end

  @tag :tmp_dir
  test "page assign in layouts always contains core page fields", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/blog.md"), """
    ---
    title: "Just another blog"
    layout: "blog"
    ---
    These are some of my ramblings.
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/lib/layouts"))

    File.write!(Path.join(tmp_dir, "/lib/layouts/blog.eex"), """
    <html>
    <title><%= @title %></title><body>
    <p>URL: <%= @page.url %></p>
    <p>input_path: <%= @page.input_path %></p>
    <p>output_path: <%= @page.output_path %></p>
    <p>date: <%= @page.date %></p>
    <%= @content %>
    </body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/lib/layouts")
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/blog/index.html"), fn file ->
      assert file =~ "URL: /blog/"
      assert file =~ "input_path: " <> Path.join(tmp_dir, "/src/blog.md")
      assert file =~ "output_path: " <> Path.join(tmp_dir, "/blog/index.html")
      assert file =~ "date: "
    end)
  end

  @tag :tmp_dir
  test "layouts can render collection data", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src/posts"))

    File.write!(Path.join(tmp_dir, "/config.exs"), """
    %{
      collections: %{
        tags: %{}
      }
    }
    """)

    File.write!(Path.join(tmp_dir, "/src/posts/a.md"), """
    ---
    title: "With Griffin you can write a blog"
    tags: "post"
    layout: "blog_entry"
    ---
    this is file A
    """)

    File.write!(Path.join(tmp_dir, "/src/posts/b.md"), """
    ---
    title: "You can also make a landing page"
    tags: "post"
    layout: "blog_entry"
    ---
    this is file B
    """)

    File.write!(Path.join(tmp_dir, "/src/blog.md"), """
    ---
    title: "Just another blog"
    layout: "blog"
    ---
    These are some of my ramblings.
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/lib/layouts"))

    File.write!(Path.join(tmp_dir, "/lib/layouts/blog.eex"), """
    <html><title><%= @title %></title><body>
    <h1>Posts</h1>
    <%= @content %>
    <ul>
      <%= for post <- @collections.tags.post do %>
        <li><a href="<%= post.data.url %>"><%= post.data.title %></a></li>
      <% end %>
    </ul>
    </body></html>
    """)

    File.write!(Path.join(tmp_dir, "/lib/layouts/blog_entry.eex"), """
    <html><title><%= @title %></title><body><%= @content %></body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      Path.join(tmp_dir, "/_site"),
      "--layouts",
      Path.join(tmp_dir, "/lib/layouts"),
      "--config",
      Path.join(tmp_dir, "/config.exs")
    ])

    assert_received {:mix_shell, :info, ["Wrote 3 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/_site/posts/a/index.html"))
    assert_file(Path.join(tmp_dir, "/_site/posts/b/index.html"))

    assert_file(Path.join(tmp_dir, "/_site/blog/index.html"), fn file ->
      assert file =~ "<title>Just another blog"
      assert file =~ "<h1>Posts"
      assert file =~ "These are some of my ramblings."
      assert file =~ "<a href=\"/posts/a/\">With Griffin you can write a blog"
      assert file =~ "<a href=\"/posts/b/\">You can also make a landing page"
    end)
  end

  @tag :tmp_dir
  test "layouts can access global assigns defined in a data file", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/data"))
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/data/favorites.exs"), """
    %{
      fruit: "🍊",
      meal: "🍝",
      place: "🌊"
    }
    """)

    File.write!(Path.join(tmp_dir, "/src/some-page.md"), """
    ---
    title: Favorites
    layout: faves
    ---
    # <%= @title %>
    Here are some of my favorite things in the world:
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/lib/layouts"))

    File.write!(Path.join(tmp_dir, "/lib/layouts/faves.eex"), """
    <html><title><%= @title %></title><body>
    <%= @content %>
    <ul>
      <%= for {category, favorite} <- @favorites do %>
        <li>My favorite <%= category %> is the <%= favorite %>.</li>
      <% end %>
    </ul>
    </body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/lib/layouts"),
      "--data",
      Path.join(tmp_dir, "/data"),
      "--debug"
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
    assert_received {:mix_shell, :info, ["Stored data in global assigns from 1 file"]}

    assert_file(Path.join(tmp_dir, "/some-page/index.html"), fn file ->
      assert file =~ "<title>Favorites"
      assert file =~ "Here are some of my favorite things in the world:"
      assert file =~ "<li>My favorite fruit is the 🍊.</li>"
      assert file =~ "<li>My favorite meal is the 🍝.</li>"
      assert file =~ "<li>My favorite place is the 🌊.</li>"
    end)
  end

  @tag :tmp_dir
  test "can handle EEx files inside input directory", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(Path.join(tmp_dir, "/src"))

    File.write!(Path.join(tmp_dir, "/src/template.eex"), """
    ---
    title: Template
    layout: home
    ---
    <h1><%= @title %></h1>
    <p>Today's lucky number is 17.</p>
    """)

    File.mkdir_p!(Path.join(tmp_dir, "/lib/layouts"))

    File.write!(Path.join(tmp_dir, "/lib/layouts/home.eex"), """
    <html><title><%= @title %></title><body>
    <%= @content %>
    </body></html>
    """)

    Build.run([
      "--input",
      Path.join(tmp_dir, "/src"),
      "--output",
      tmp_dir,
      "--layouts",
      Path.join(tmp_dir, "/lib/layouts")
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(Path.join(tmp_dir, "/template/index.html"), fn file ->
      assert file =~ "<title>Template"
      assert file =~ "<h1>Template"
      assert file =~ "<p>Today's lucky number is 17.</p>"
    end)
  end
end
