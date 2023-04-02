Code.require_file("../../../installer/test/mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Grf.BuildTest do
  use ExUnit.Case
  import MixHelper
  import Assertions, only: [assert_lists_equal: 2]

  # Missing tests:
  # - config hierarchy
  # - nested shortcodes
  # - hook event arguments
  # - nested layouts
  # - rendering variables in templates
  # - not rendering files that have draft in front matter

  @input_path "empty_input_path"
  test "doesn't work on any files when given an empty input directory" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      Mix.Tasks.Grf.Build.run(["--input", @input_path])
      assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
    end)
  end

  @input_path "file_path_relative_input"
  @output_path "file_path_relative_output"
  test "files are output to the same relative directory as the input directory" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path <> "/a/b/c")

      File.write!(@input_path <> "/a/b/c/d.md", """
      # Testing output
      This is supposed to go to <output>/a/b/c/d/index.html
      """)

      Mix.Tasks.Grf.Build.run(["--input", @input_path, "--output", @output_path])
      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
      assert_file(@output_path <> "/a/b/c/d/index.html")
    end)
  end

  @input_path "index_files_input"
  @output_path "index_files_output"
  test "input files with name `index` get written to the same relative directory" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path <> "/a/b/c")

      File.write!(@input_path <> "/a/b/c/index.md", """
      # Testing output
      Since this is an index file,
      the output is supposed to go to <output>/a/b/c/index.html
      """)

      Mix.Tasks.Grf.Build.run(["--input", @input_path, "--output", @output_path])
      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
      assert_file(@output_path <> "/a/b/c/index.html")
    end)
  end

  @input_path "one_layout_multiple_partials_input"
  @output_path "one_layout_multiple_partials_output"
  test "one layout can include multiple partials" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
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

      File.mkdir_p!(@input_path <> "/layouts/partials")

      File.write!(@input_path <> "/layouts/a.eex", """
      <html><title><%= @title %></title><body>
      <%= @partials.one %>
      <%= @partials.two %>
      <%= @content %>
      <%= @partials.three %>
      </body></html>
      """)

      File.write!(@input_path <> "/layouts/partials/one.eex", """
      <div id="one"><%= @foo %></div>
      """)

      File.write!(@input_path <> "/layouts/partials/two.eex", """
      <div id="two"><%= @bar %></div>
      """)

      File.write!(@input_path <> "/layouts/partials/three.eex", """
      <div id="three"><%= @baz %></div>
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--layouts",
        @input_path <> "/layouts"
      ])

      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

      assert_file(@output_path <> "/a/index.html", fn file ->
        assert file =~ "<div id=\"one\">"
        assert file =~ "Foo"
        assert file =~ "<div id=\"two\">"
        assert file =~ "Bar"
        assert file =~ "File A"
        assert file =~ "this is file A"
        assert file =~ "<div id=\"three\">"
        assert file =~ "Baz"
      end)
    end)
  end

  @input_path "multiple_layouts_input"
  @output_path "multiple_layouts_output"
  test "can render multiple different layouts" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
      ---
      title: "A"
      layout: "a"
      ---
      # File A
      this is file A
      """)

      File.write!(@input_path <> "/b.md", """
      ---
      title: "B"
      layout: "b"
      ---
      # File B
      this is file B
      """)

      File.mkdir_p!(@input_path <> "/layouts")

      File.write!(@input_path <> "/layouts/a.eex", """
      <html><title><%= @title %></title><body><div id="a"><%= @content%></div></body></html>
      """)

      File.write!(@input_path <> "/layouts/b.eex", """
      <html><title><%= @title %></title><body><div id="b"><%= @content%></div></body></html>
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--layouts",
        @input_path <> "/layouts"
      ])

      assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}

      assert_file(@output_path <> "/a/index.html", fn file ->
        assert file =~ "<div id=\"a\">"
        assert file =~ "File A"
        refute file =~ "<div id=\"b\">"
        refute file =~ "File B"
      end)

      assert_file(@output_path <> "/b/index.html", fn file ->
        assert file =~ "<div id=\"b\">"
        assert file =~ "File B"
        refute file =~ "<div id=\"a\">"
        refute file =~ "File A"
      end)
    end)
  end

  @input_path "default_layout_input"
  @output_path "default_layout_output"
  test "pages without a layout use the fallback HTML layout" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
      # File A
      this is file A
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path
      ])

      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

      assert_file(@output_path <> "/a/index.html", fn file ->
        assert file =~ "<!DOCTYPE html>"

        assert file =~
                 "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"

        assert file =~ "this is file A"
      end)
    end)
  end

  @input_path "front_matter_input"
  @output_path "front_matter_output"
  test "front matter is reflected in the final output of the file" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/d.md", """
      ---
      title: "My custom title"
      ---
      # Testing output
      The HTML page is supposed to have a title defined
      from the front matter.
      """)

      Mix.Tasks.Grf.Build.run(["--input", @input_path, "--output", @output_path])
      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

      assert_file(@output_path <> "/d/index.html", fn file ->
        assert file =~ "<title>My custom title</title>"
      end)
    end)
  end

  @input_path "permalinks_input"
  @output_path "permalinks_output"
  test "pages with permalinks get written to the right directory" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
      ---
      title: "A"
      permalink: "alpha/delta/gamma/some-custom-page"
      ---
      # File A
      this is file A
      """)

      File.write!(@input_path <> "/b.md", """
      ---
      title: "B"
      permalink: "beta"
      ---
      # File B
      this is file B
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path
      ])

      assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}

      assert_file(@output_path <> "/alpha/delta/gamma/some-custom-page/index.html", fn file ->
        assert file =~ "this is file A"
      end)

      assert_file(@output_path <> "/beta/index.html", fn file ->
        assert file =~ "this is file B"
      end)
    end)
  end

  @input_path "passthrough_copies_input"
  @output_path "passthrough_copies_output"
  test "passthrough copies files to the correct path" do
    icon = File.read!("priv/static/favicon.ico")
    img = File.read!("priv/static/griffin.png")

    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      File.mkdir_p!("assets/js")
      File.mkdir_p!("assets/css")
      File.mkdir_p!("static")

      File.write!("assets/js/test.js", """
      console.log("griffin")
      """)

      File.write!("assets/css/test.css", """
      /* griffin */
      """)

      File.write!("static/favicon.ico", icon)
      File.write!("static/griffin.png", img)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--passthrough-copies",
        "assets,static/*.ico"
      ])

      assert_file(@output_path <> "/assets/js/test.js", fn file ->
        assert file =~ "console.log(\"griffin\")"
      end)

      assert_file(@output_path <> "/assets/css/test.css", fn file ->
        assert file =~ "/* griffin */"
      end)

      # assert that wildcard was handled as expected
      assert_file(@output_path <> "/static/favicon.ico")
      refute_file(@output_path <> "/static/griffin.png")
    end)
  end

  @input_path "hooks_input"
  test "calls hooks before and after executing" do
    config_file = File.read!("test/files/config/hooks_only.ex")

    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      :ok = File.write(@input_path <> "/config.ex", config_file)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--config",
        @input_path <> "/config.ex"
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
        input: @input_path,
        output: "_site",
        layouts: "lib/layouts",
        partials: "lib/layouts/partials"
      }

      expected_directories = "#{inspect(directories)}"

      assert directories_before == expected_directories
      assert directories_after == expected_directories
      assert timestamp_before <= timestamp_after
    end)
  end

  @input_path "ignores_input"
  @output_path "ignores_output"
  test "ignores files specified via CLI arguments" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path <> "/process/other")
      File.mkdir_p!(@input_path <> "/ignore/some")

      File.write!(@input_path <> "/ignore/some/file.md", """
      # This won't be processed
      """)

      File.write!(@input_path <> "/process/other/file.md", """
      # But this will
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--ignore",
        @input_path <> "/ignore/**"
      ])

      refute_file(@output_path <> "/ignore/some/file/index.html")

      assert_file(@output_path <> "/process/other/file/index.html", fn file ->
        assert file =~ "But this will"
      end)

      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}
    end)
  end

  @input_path "filters_input"
  @output_path "filters_output"
  test "filters can be used in layouts correctly" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
      ---
      title: "title"
      layout: "a"
      ---
      # griffin filters
      this will be uppercase
      """)

      File.mkdir_p!(@input_path <> "/layouts")

      # use the default uppercase filter
      File.write!(@input_path <> "/layouts/a.eex", """
      <html><title><%= @title %></title>
      <body>
      <%= @content |> @uppercase.() %>
      <hr />
      </body></html>
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--layouts",
        @input_path <> "/layouts"
      ])

      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

      assert_file(@output_path <> "/a/index.html", fn file ->
        assert file =~ "GRIFFIN FILTERS"
        assert file =~ "THIS WILL BE UPPERCASE"
      end)
    end)
  end

  @input_path "shortcodes_input"
  @output_path "shortcodes_output"
  test "shortcodes can be used in layouts correctly" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
      ---
      title: "title"
      video_slug: "dQw4w9WgXcQ"
      layout: "a"
      ---
      # Cool video
      This is a cool video you should watch
      """)

      File.mkdir_p!(@input_path <> "/layouts")

      # use the default shortcode for youtube videos
      File.write!(@input_path <> "/layouts/a.eex", """
      <html><title><%= @title %></title>
      <body>
      <%= @content %>
      <hr />
      <%= @youtube.(@video_slug) %>
      </body></html>
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--layouts",
        @input_path <> "/layouts"
      ])

      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

      assert_file(@output_path <> "/a/index.html", fn file ->
        assert file =~ "This is a cool video you should watch"
        assert file =~ "src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\""
      end)
    end)
  end

  @input_path "config_input"
  @output_path "config_ouput"
  test "a config file can be passed in to configure Griffin" do
    config_file = """
    %{
      input: \"#{@input_path <> "/source"}\",
      output: \"#{@output_path <> "/public"}\",
      layouts: \"#{@input_path <> "/cooldesignsinc"}\"
    }
    """

    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      :ok = File.write(@input_path <> "/config.ex", config_file)

      File.mkdir_p!(@input_path <> "/source")

      File.write!(@input_path <> "/source/file.md", """
      ---
      layout: "conf"
      ---
      # Config is tricky
      """)

      File.mkdir_p!(@input_path <> "/cooldesignsinc")

      File.write!(@input_path <> "/cooldesignsinc/conf.eex", """
      <html><body><div id="config-test"><%= @content %></div></body></html>
      """)

      Mix.Tasks.Grf.Build.run(["--config", @input_path <> "/config.ex"])

      assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

      assert_file(@output_path <> "/public/file/index.html", fn file ->
        assert file =~ "<div id=\"config-test\">"
        assert file =~ "Config is tricky"
      end)
    end)
  end

  @input_path "quiet_input"
  @output_path "quiet_ouput"
  test "quiet option has intended effect" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/one.md", """
      # one
      """)

      File.write!(@input_path <> "/two.md", """
      # two
      """)

      Mix.Tasks.Grf.Build.run(["--input", @input_path, "--output", @output_path, "--quiet"])

      assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}
      refute_received {:mix_shell, :info, ["Compiled 0 layouts (0 partials)"]}
      refute_received {:mix_shell, :info, ["writing: " <> _]}

      assert_file(@output_path <> "/one/index.html")
      assert_file(@output_path <> "/two/index.html")
    end)
  end

  @input_path "dry_run_input"
  @output_path "dry_run_output"
  test "dry run option prevents writing to the file system" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      File.mkdir_p!("assets/js")
      File.mkdir_p!("assets/css")
      File.mkdir_p!("static")

      File.write!("assets/js/test.js", "")
      File.write!("assets/css/test.css", "")

      File.write!("static/favicon.ico", "")
      File.write!("static/griffin.png", "")

      File.mkdir_p!(@input_path <> "/process/some")
      File.mkdir_p!(@input_path <> "/process/other")

      File.write!(@input_path <> "/process/some/file.md", """
      # This won't be written to file system
      """)

      File.write!(@input_path <> "/process/other/file.md", """
      # Neither will this
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--passthrough-copies",
        "assets,static",
        "--dry-run"
      ])

      # this message might change in the future
      assert_received {:mix_shell, :info, ["Wrote 2 files in " <> _]}

      # neither assets nor markdown files were actually written
      refute_file(@output_path <> "/assets/js/test.js")
      refute_file(@output_path <> "/assets/css/test.css")
      refute_file(@output_path <> "/static/favicon.ico")
      refute_file(@output_path <> "/static/griffin.png")

      refute_file(@output_path <> "/process/some/file/index.html")
      refute_file(@output_path <> "/process/other/file/index.html")
    end)
  end

  @tag :tmp_dir
  test "collections are generated correctyly", %{tmp_dir: tmp_dir} do
    File.write!(tmp_dir <> "/notags.md", """
    ---
    title: "no tags"
    ---
    # I have no tags
    """)

    File.write!(tmp_dir <> "/onetag.md", """
    ---
    tags: "post"
    ---
    # I have one tag
    """)

    File.write!(tmp_dir <> "/moretags.md", """
    ---
    tags:
      - post
      - personal
      - tldr
    ---
    # I have three tags
    """)

    File.write!(tmp_dir <> "/evenmore.md", """
    ---
    tags: ["personal"]
    ---
    # I also have tags but in different yaml
    """)

    Mix.Tasks.Grf.Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir,
      "--debug"
    ])

    assert_file(tmp_dir <> "/notags/index.html")
    assert_file(tmp_dir <> "/onetag/index.html")
    assert_file(tmp_dir <> "/moretags/index.html")
    assert_file(tmp_dir <> "/evenmore/index.html")

    assert_received {:mix_shell, :info, ["Wrote 4 files in " <> _]}
    assert_received {:mix_shell, :info, ["Collections: personal, post, tldr"]}
    assert_received {:mix_shell, :info, ["Collection personal: " <> personal_tagged_csv]}
    assert_received {:mix_shell, :info, ["Collection post: " <> post_tagged_csv]}
    assert_received {:mix_shell, :info, ["Collection tldr: " <> tldr_tagged_csv]}

    one_tag_file = Path.absname(tmp_dir <> "/onetag.md")
    more_tags_file = Path.absname(tmp_dir <> "/moretags.md")
    even_more_file = Path.absname(tmp_dir <> "/evenmore.md")

    personal_collection = String.split(personal_tagged_csv, ",")
    post_collection = String.split(post_tagged_csv, ",")
    tldr_collection = String.split(tldr_tagged_csv, ",")

    assert_lists_equal(personal_collection, [more_tags_file, even_more_file])
    assert_lists_equal(post_collection, [one_tag_file, more_tags_file])
    assert_lists_equal(tldr_collection, [more_tags_file])
  end

  @tag :tmp_dir
  test "page assign in layouts always contains core page fields", %{tmp_dir: tmp_dir} do
    File.write!(tmp_dir <> "/blog.md", """
    ---
    title: "Just another blog"
    layout: "blog"
    ---
    These are some of my ramblings.
    """)

    File.mkdir_p!(tmp_dir <> "/lib/layouts")

    File.write!(tmp_dir <> "/lib/layouts/blog.eex", """
    <html>
    <title><%= @title %></title><body>
    <p>URL: <%= @page.url %></p>
    <p>input_path: <%= @page.input_path %></p>
    <p>output_path: <%= @page.output_path %></p>
    <p>date: <%= @page.date %></p>
    <%= @content %>
    </body></html>
    """)

    Mix.Tasks.Grf.Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir,
      "--layouts",
      tmp_dir <> "/lib/layouts"
    ])

    assert_received {:mix_shell, :info, ["Wrote 1 files in " <> _]}

    assert_file(tmp_dir <> "/blog/index.html", fn file ->
      assert file =~ "URL: /blog/"
      assert file =~ "input_path: " <> tmp_dir <> "/blog.md"
      assert file =~ "output_path: " <> tmp_dir <> "/blog/index.html"
      assert file =~ "date: "
      # assert that it's a valid date also
      # assert {:ok, _, _} = DateTime.from_iso8601(date)
    end)
  end

  @tag :tmp_dir
  test "layouts can render collection data", %{tmp_dir: tmp_dir} do
    File.mkdir_p!(tmp_dir <> "/posts")

    File.write!(tmp_dir <> "/posts/a.md", """
    ---
    title: "With Griffin you can write a blog"
    tags: "post"
    layout: "blog_entry"
    ---
    this is file A
    """)

    File.write!(tmp_dir <> "/posts/b.md", """
    ---
    title: "You can also make a landing page"
    tags: "post"
    layout: "blog_entry"
    ---
    this is file B
    """)

    File.write!(tmp_dir <> "/blog.md", """
    ---
    title: "Just another blog"
    layout: "blog"
    ---
    These are some of my ramblings.
    """)

    File.mkdir_p!(tmp_dir <> "/lib/layouts")

    File.write!(tmp_dir <> "/lib/layouts/blog.eex", """
    <html><title><%= @title %></title><body>
    <h1>Posts</h1>
    <%= @content %>
    <ul>
      <%= for post <- @collections.post do %>
        <li><a href="<%= post.data.url %>"><%= post.data.title %></a></li>
      <% end %>
    </ul>
    </body></html>
    """)

    File.write!(tmp_dir <> "/lib/layouts/blog_entry.eex", """
    <html><title><%= @title %></title><body><%= @content %></body></html>
    """)

    Mix.Tasks.Grf.Build.run([
      "--input",
      tmp_dir,
      "--output",
      tmp_dir,
      "--layouts",
      tmp_dir <> "/lib/layouts"
    ])

    assert_received {:mix_shell, :info, ["Wrote 3 files in " <> _]}

    assert_file(tmp_dir <> "/posts/a/index.html")
    assert_file(tmp_dir <> "/posts/b/index.html")

    assert_file(tmp_dir <> "/blog/index.html", fn file ->
      assert file =~ "<title>Just another blog"
      assert file =~ "<h1>Posts"
      assert file =~ "These are some of my ramblings."
      assert file =~ "<a href=\"/posts/a/\">With Griffin you can write a blog"
      assert file =~ "<a href=\"/posts/b/\">You can also make a landing page"
    end)
  end
end
