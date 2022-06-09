defmodule Grf.New.Generator do
  @moduledoc false
  @version Mix.Project.config()[:version]

  def run(project) do
    for {input, output} <- template_files(project),
        do: copy_file(input, output, project)
  end

  defp template_files(project) do
    [
      {"/config/config.exs", "config/config.exs"},
      # {"/config/dev.exs", "config/dev.exs"},
      # {"/config/prod.exs", "config/prod.exs"},
      # {"/config/test.exs", "config/test.exs"},
      {"/lib/app_name.ex", "lib/#{project.app_name}.ex"},
      {"/priv/content/assets/style.css", "priv/content/assets/style.css"},
      {"/priv/content/index.md", "priv/content/index.md"},
      {"/priv/layouts/default.html.eex", "priv/layouts/default.html.eex"},

      # {"/formatter.exs", ".formatter.exs"},
      {"/gitignore", ".gitignore"},
      {"/mix.exs", "mix.exs"},
      {"/README.md", "README.md"}
    ]
  end

  defp copy_file(input, output, project) do
    input_path = template_path(input)
    output_path = project.path <> output
    metadata = eex_metadata(project)
    Mix.Generator.copy_template(input_path, output_path, metadata)
  end

  defp template_path(input) do
    Path.join(Application.app_dir(:grf_new, "priv/templates"), input)
  end

  defp eex_metadata(project) do
    [
      griffin_dep: "{:griffin_ssg, \"~> 0.1\"}",
      griffin_github_version_tag: @version,
      output_path: "_site",
      input_path: "priv",
      app_module: project.module,
      app_name: project.app_name,
      version: project.version
    ]
  end
end
