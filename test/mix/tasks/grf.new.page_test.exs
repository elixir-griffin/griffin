Code.require_file("../../../installer/test/mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Grf.New.PageTest do
  use ExUnit.Case
  import MixHelper

  @tmp_dir "single_path"
  test "writes a new markdown file when called with a single path" do
    in_tmp(@tmp_dir, fn ->
      Mix.Tasks.Grf.New.Page.run(["test.md"])

      assert_file("test.md", fn file ->
        assert file =~ "title: \"test.md\""
        assert file =~ "date: "
        assert file =~ "draft: false"
      end)
    end)
  end

  @tmp_dir "title_option"
  test "the title changes with the --title option" do
    in_tmp(@tmp_dir, fn ->
      Mix.Tasks.Grf.New.Page.run(["--title", "Testing testing 123", "test.md"])

      assert_file("test.md", fn file ->
        assert file =~ "title: \"Testing testing 123\""
      end)
    end)
  end

  @tmp_dir "draft_option"
  test "the draft status is set to true with the --draft option" do
    in_tmp(@tmp_dir, fn ->
      Mix.Tasks.Grf.New.Page.run(["--draft", "test.md"])

      assert_file("test.md", fn file ->
        assert file =~ "draft: true"
      end)
    end)
  end
end
