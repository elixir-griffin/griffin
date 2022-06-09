Code.require_file "mix_helper.exs", __DIR__

defmodule Mix.Tasks.Grf.NewTest do
  use ExUnit.Case, async: false
  import MixHelper
  import ExUnit.CaptureIO

  @app_name "griffin_blog"

  setup do
    # The shell asks to install deps.
    # We will politely say not.
    send self(), {:mix_shell_input, :yes?, false}
    :ok
  end

  test "assets are in sync with installer" do
    for file <- ~w(favicon.ico logo.png) do
      assert File.read!("../priv/static/#{file}") ==
        File.read!("priv/templates/priv/content/assets/#{file}")
    end
  end

  test "returns the version" do
    Mix.Tasks.Grf.New.run(["-v"])
    assert_received {:mix_shell, :info, ["Griffin installer v" <> _]}
  end

  test "new with defaults" do
    in_tmp "new with defaults", fn ->
      Mix.Tasks.Grf.New.run([@app_name])

      assert_file "griffin_blog/README.md"

      assert_file "griffin_blog/mix.exs", fn file ->
        assert file =~ "app: :griffin_blog"
        refute file =~ "deps_path: \"../../deps\""
        refute file =~ "lockfile: \"../../mix.lock\""
      end

      assert_file "griffin_blog/config/config.exs", fn file ->
        assert file =~ "config :griffin_ssg, :output_path, \"_site\""
        assert file =~ "config :griffin_ssg, :input_path, \"priv/content\""
      end

      assert_file "griffin_blog/lib/griffin_blog.ex", ~r/defmodule GriffinBlog do/
      assert_file "griffin_blog/mix.exs", fn file ->
        assert file =~ "{:griffin_ssg,"
      end

      assert_file "griffin_blog/priv/layouts/default.html.eex"
      assert_file "griffin_blog/priv/content/index.md"

      # TODO: add assertions for generated test files

      # assets
      assert_file "griffin_blog/.gitignore", fn file ->
        assert file =~ "/_site/"
        assert file =~ "griffin_blog-*.tar"
        assert file =~ ~r/\n$/
      end

      # Install dependencies?
      # assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      # assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      # assert msg =~ "$ cd griffin_blog"
      # assert msg =~ "$ mix deps.get"
    end
  end

  test "new without defaults" do
    in_tmp "new without defaults", fn ->
      Mix.Tasks.Grf.New.run([@app_name, "--input-path", "src", "--output-path", "public"])

      # TODO: write assertions for input and output paths
    end
  end

  @tag :skip
  test "new with uppercase" do
    in_tmp "new with uppercase", fn ->
      Mix.Tasks.Grf.New.run(["griffinBlog"])

      assert_file "griffinBlog/README.md"

      assert_file "griffinBlog/mix.exs", fn file ->
        assert file =~ "app: :griffinBlog"
      end
    end
  end

  test "new with invalid args" do
    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Grf.New.run ["007invalid"]
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Phx.New.run ["string"]
    end
  end

  test "new without args" do
    in_tmp "new without args", fn ->
      assert capture_io(fn -> Mix.Tasks.Grf.New.run([]) end) =~
             "Creates a new Griffin project."
    end
  end
end
