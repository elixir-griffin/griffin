defmodule GriffinSSG.File.WatcherTest do
  use ExUnit.Case, async: true

  alias GriffinSSG.File.Watcher

  describe "file watcher" do
    @tag :tmp_dir
    test "calls the callback on file change", %{tmp_dir: tmp_dir} do
      self = self()
      {:ok, _} = Watcher.start_link([tmp_dir], fn -> send(self, :changes_detected) end)
      :timer.sleep(10)
      File.write!(tmp_dir <> "/file.txt", "test")
      assert_receive :changes_detected, 1_000
    end
  end
end
