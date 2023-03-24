Code.require_file("../../../installer/test/mix_helper.exs", __DIR__)

defmodule Grf.BuildTest do
  use ExUnit.Case, async: true
  import MixHelper

  @input_path "multiple_layouts_input"
  @output_path "multiple_layouts_output"
  test "can render multiple different layouts" do
    in_tmp(@input_path, fn ->
      File.mkdir_p!(@input_path)

      File.write!(@input_path <> "/a.md", """
      ---
      title: "A"
      layout: "a.eex"
      ---
      # File A
      this is file A
      """)

      File.write!(@input_path <> "/b.md", """
      ---
      title: "B"
      layout: "b.eex"
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
      layout: "a.eex"
      ---
      # File A
      this is file A
      """)

      File.mkdir_p!(@input_path <> "/layouts/partials")

      File.write!(@input_path <> "/layouts/a.eex", """
      <html><title><%= @title %></title><body>
      <%= @partials[:"one.eex"] %>
      <%= @partials[:"two.eex"] %>
      <%= @content %>
      <%= @partials[:"three.eex"] %>
      </div></body></html>
      """)

      File.write!(@input_path <> "/layouts/partials/one.eex", """
      <div id="one"><%= @foo %></div></body></html>
      """)

      File.write!(@input_path <> "/layouts/partials/two.eex", """
      <div id="two"><%= @bar %></div></body></html>
      """)

      File.write!(@input_path <> "/layouts/partials/three.eex", """
      <div id="three"><%= @baz %></div></body></html>
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
