defmodule GriffinFsTest do
  use ExUnit.Case, async: true
  import Assertions, only: [assert_lists_equal: 2]

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

  @tag :tmp_dir
  test "returns a complete list of files when searching the base directory", %{tmp_dir: tmp_dir} do
    setup_files(@files, tmp_dir)

    prefixed_files = Enum.map(@files, fn file -> tmp_dir <> "/" <> file end)
    assert assert_lists_equal(prefixed_files, GriffinFs.list_all(tmp_dir))
  end

  @tag :tmp_dir
  test "can expand wildcard paths as expected", %{tmp_dir: tmp_dir} do
    setup_files(@files, tmp_dir)

    prefixed_files = Enum.map(@files, fn file -> tmp_dir <> "/" <> file end)
    assert assert_lists_equal(prefixed_files, GriffinFs.list_all(tmp_dir <> "/**"))

    assert length(GriffinFs.list_all(tmp_dir <> "/**/*.{png,jpeg}")) == 4
    assert length(GriffinFs.list_all(tmp_dir <> "/**/*.mp4")) == 2
    assert length(GriffinFs.list_all(tmp_dir <> "/**/img.*")) == 3

    assert [] == GriffinFs.list_all(tmp_dir <> "/*.mp4")
    assert [] == GriffinFs.list_all(tmp_dir <> "/f/*.cpp")
    assert [] == GriffinFs.list_all(tmp_dir <> "/**/*.lua")
  end

  test "calculates files output paths correctly" do
    assert GriffinFs.output_filepath("index.md", ".", "_site") == "_site/index.html"
    assert GriffinFs.output_filepath("file.md", ".", "_site") == "_site/file/index.html"

    assert GriffinFs.output_filepath("index.md", "", "_site") == "_site/index.html"
    assert GriffinFs.output_filepath("file.md", "", "_site") == "_site/file/index.html"

    assert GriffinFs.output_filepath("a/b/c/index.md", "a", "_site") == "_site/b/c/index.html"
    assert GriffinFs.output_filepath("a/b/c/file.md", "a", "_site") == "_site/b/c/file/index.html"

    assert GriffinFs.output_filepath("a/b/c/index.md", "a/b/c", "_site") == "_site/index.html"
    assert GriffinFs.output_filepath("a/b/c/file.md", "a/b/c", "_site") == "_site/file/index.html"

    assert GriffinFs.output_filepath("a/b/c/index.md", "", "_site") == "_site/a/b/c/index.html"

    assert GriffinFs.output_filepath("a/b/c/file.md", "", "_site") ==
             "_site/a/b/c/file/index.html"

    assert GriffinFs.output_filepath("a/b/c/index.md", ".", "_site") == "_site/a/b/c/index.html"

    assert GriffinFs.output_filepath("a/b/c/file.md", ".", "_site") ==
             "_site/a/b/c/file/index.html"
  end

  test "reads gitignore files correctly" do
    assert GriffinFs.git_ignores(".gitignore") == [
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
