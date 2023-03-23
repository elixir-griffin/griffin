Code.require_file "../../../installer/test/mix_helper.exs", __DIR__

defmodule Grf.BuildTest do
  use ExUnit.Case
  import MixHelper

  @input_path "empty_input_path"
  test "doesn't work on any files when given an empty input directory" do
    in_tmp @input_path, fn ->
      File.mkdir_p!(@input_path)
      Mix.Tasks.Grf.Build.run(["--input", @input_path])
      assert_received {:mix_shell, :info, ["Wrote 0 files in " <> _]}
    end
  end
end
