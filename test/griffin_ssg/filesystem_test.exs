defmodule GriffinSSG.FilesystemTest do
  use ExUnit.Case, async: true

  import Assertions, only: [assert_lists_equal: 2]

  alias GriffinSSG.Filesystem

  @files [
    "a/b/c/doc.md",
    "a/b/c/favicon.ico",
    "a/b/c/img.webp",
    "a/b/c/img.png",
    "a/b/c/font.woff2",
    "a/b/c/doc.docx",
    "a/b/c/img.jpeg",
    "f/meme.jpeg",
    "f/videoclip.mp4",
    "f/elixir.ex",
    "post.md",
    "d/e/cat.gif",
    "d/e/vector.svg",
    "d/e/other-img.png",
    "d/e/footage.mp4",
    "d/e/results.csv",
    "d/e/book.mobi"
  ]

  describe "copy_all/2" do
    # @tag :tmp_dir
    @tag :skip
    test "returns `{:ok, count}` when all files are successfully copied", %{tmp_dir: tmp_dir} do
      setup_files(@files, tmp_dir)
      directories = [tmp_dir]
      destination = Path.join(tmp_dir, "/zzz")
      result = Filesystem.copy_all(directories, destination)

      assert result == {:ok, length(@files)}

      for file <- @files do
        assert File.exists?(destination <> file)
      end
    end
  end

  @tag :tmp_dir
  test "returns a complete list of files when searching the base directory", %{tmp_dir: tmp_dir} do
    setup_files(@files, tmp_dir)

    prefixed_files = Enum.map(@files, fn file -> Path.join(tmp_dir, file) end)
    assert_lists_equal(prefixed_files, Filesystem.list_all(tmp_dir))
  end

  @tag :tmp_dir
  test "can expand wildcard paths as expected", %{tmp_dir: tmp_dir} do
    setup_files(@files, tmp_dir)

    prefixed_files = Enum.map(@files, fn file -> Path.join(tmp_dir, file) end)
    assert_lists_equal(prefixed_files, Filesystem.list_all(Path.join(tmp_dir, "/**")))

    assert length(Filesystem.list_all(Path.join(tmp_dir, "/**/*.{png,jpeg}"))) == 4
    assert length(Filesystem.list_all(Path.join(tmp_dir, "/**/*.mp4"))) == 2
    assert length(Filesystem.list_all(Path.join(tmp_dir, "/**/img.*"))) == 3

    assert [] == Filesystem.list_all(Path.join(tmp_dir, "/*.mp4"))
    assert [] == Filesystem.list_all(Path.join(tmp_dir, "/f/*.cpp"))
    assert [] == Filesystem.list_all(Path.join(tmp_dir, "/**/*.lua"))
  end

  test "calculates files output paths correctly" do
    assert Filesystem.output_filepath("index.md", ".", "_site") == "_site/index.html"
    assert Filesystem.output_filepath("file.md", ".", "_site") == "_site/file/index.html"

    assert Filesystem.output_filepath("index.md", "", "_site") == "_site/index.html"
    assert Filesystem.output_filepath("file.md", "", "_site") == "_site/file/index.html"

    assert Filesystem.output_filepath("a/b/c/index.md", "a", "_site") == "_site/b/c/index.html"

    assert Filesystem.output_filepath("a/b/c/file.md", "a", "_site") ==
             "_site/b/c/file/index.html"

    assert Filesystem.output_filepath("a/b/c/index.md", "a/b/c", "_site") == "_site/index.html"

    assert Filesystem.output_filepath("a/b/c/file.md", "a/b/c", "_site") ==
             "_site/file/index.html"

    assert Filesystem.output_filepath("a/b/c/index.md", "", "_site") == "_site/a/b/c/index.html"

    assert Filesystem.output_filepath("a/b/c/file.md", "", "_site") ==
             "_site/a/b/c/file/index.html"

    assert Filesystem.output_filepath("a/b/c/index.md", ".", "_site") == "_site/a/b/c/index.html"

    assert Filesystem.output_filepath("a/b/c/file.md", ".", "_site") ==
             "_site/a/b/c/file/index.html"
  end

  test "reads gitignore files correctly" do
    assert Filesystem.git_ignores(".gitignore") == [
             "_build",
             "cover",
             "deps",
             "doc",
             ".fetch",
             "erl_crash.dump",
             "*.ez",
             "griffin_ssg-*.tar",
             "tmp",
             "installer/_build",
             "installer/assets",
             "installer/deps",
             "installer/doc",
             "installer/grf_new-*.ez",
             "_site"
           ]
  end

  defp setup_files(files, dirname) do
    for file <- files do
      File.mkdir_p!(dirname <> "/" <> Path.dirname(file))
      File.write!(dirname <> "/" <> file, "")
    end
  end
end
