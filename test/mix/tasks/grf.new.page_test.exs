defmodule Mix.Tasks.Grf.New.PageTest do
  use ExUnit.Case, async: true

  import GriffinFileHelper

  alias Mix.Tasks.Grf.New.Page

  @tag :tmp_dir
  test "writes a new markdown file when called with a single path", %{tmp_dir: tmp_dir} do
    Page.run([Path.join(tmp_dir, "/test.md")])

    assert_file(Path.join(tmp_dir, "/test.md"), fn file ->
      assert file =~ "title: \"#{tmp_dir}/test.md\""
      assert file =~ "date: "
      assert file =~ "draft: false"
    end)
  end

  @tag :tmp_dir
  test "the title changes with the --title option", %{tmp_dir: tmp_dir} do
    Page.run(["--title", "Testing testing 123", Path.join(tmp_dir, "/test.md")])

    assert_file(Path.join(tmp_dir, "/test.md"), fn file ->
      assert file =~ "title: \"Testing testing 123\""
    end)
  end

  @tag :tmp_dir
  test "the draft status is set to true with the --draft option", %{tmp_dir: tmp_dir} do
    Page.run(["--draft", Path.join(tmp_dir, "/test.md")])

    assert_file(Path.join(tmp_dir, "/test.md"), fn file ->
      assert file =~ "draft: true"
    end)
  end
end
