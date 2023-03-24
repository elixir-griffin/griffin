Code.require_file("../../../installer/test/mix_helper.exs", __DIR__)

defmodule Grf.BuildTest do
  use ExUnit.Case
  import MixHelper

  @input_path "hooks_input"
  @output_path "hooks_output"
  test "calls hooks before and after executing" do
    in_tmp(@input_path, fn ->
      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path
      ])

      assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
      assert_received {:mix_shell, :info, ["I was called before build: " <> timestamp_before]}
      assert_received {:mix_shell, :info, ["I was called after build: " <> timestamp_after]}

      assert timestamp_before <= timestamp_after
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

  @input_path "ignores_input"
  @output_path "ignores_output"
  test "ignores files specified via CLI arguments" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      File.mkdir_p!("ignore/some")
      File.mkdir_p!("ignore/other")

      File.write!("ignore/some/file.md", """
      # This won't be processed
      """)

      File.write!("ignore/other/file.md", """
      neither will this
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--ignore",
        "ignore/some/*,ignore/others/*"
      ])

      refute_file(@output_path <> "ignore/some/file.md")
      refute_file(@output_path <> "/ignore/other/file.md")

      assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
    end)
  end

  @input_path "passthrough_copies_input"
  @output_path "passthrough_copies_output"
  test "passthrough copies files to the correct path" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      File.mkdir_p!("assets/js")
      File.mkdir_p!("assets/css")

      File.write!("assets/js/test.js", """
      console.log("griffin")
      """)

      File.write!("assets/css/test.css", """
      /* griffin */
      """)

      Mix.Tasks.Grf.Build.run([
        "--input",
        @input_path,
        "--output",
        @output_path,
        "--passthrough-copies",
        "assets/js/*,assets/css/*"
      ])

      assert_file(@output_path <> "/assets/js/test.js", fn file ->
        assert file =~ "console.log(\"griffin\")"
      end)

      assert_file(@output_path <> "/assets/css/test.css", fn file ->
        assert file =~ "/* griffin */"
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

  @input_path "empty_input_path"
  test "doesn't work on any files when given an empty input directory" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)
      Mix.Tasks.Grf.Build.run(["--input", @input_path])
      assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
    end)
  end
end
