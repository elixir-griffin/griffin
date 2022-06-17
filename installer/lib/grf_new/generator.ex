defmodule Grf.New.Generator do
  @moduledoc false
  @version Mix.Project.config()[:version]

  def run(project) do
    for {input, output} <- template_files(project),
        do: copy_template(input, output, project)

    for {input, output} <- assets(project),
        do: copy_file(input, output, project)

    project
  end

  defp template_files(project) do
    [
      {"/config/config.exs", "/config/config.exs"},

      {"/lib/app_name.ex", "/lib/#{project.app_name}.ex"},
      {"/priv/content/index.md", "/priv/content/index.md"},
      {"/priv/layouts/default.html.eex", "/lib/layouts/default.html.eex"},

      {"/gitignore", "/.gitignore"},
      {"/mix.exs", "/mix.exs"},
      {"/README.md", "/README.md"}
    ]
  end

  defp assets(_project) do
    [
      {"/assets/favicon.ico", "/assets/favicon.ico"},
      {"/assets/griffin-icon.png", "/assets/griffin-icon.png"},
      {"/assets/griffin.png", "/assets/griffin.png"},
      {"/assets/style.css", "/assets/style.css"}
  ]
  end

  defp copy_template(input, output, project) do
    input_path = template_path(input)
    output_path = project.path <> output
    metadata = eex_metadata(project)
    Mix.Generator.copy_template(input_path, output_path, metadata)
  end

  defp copy_file(input, output, project) do
    input_path = template_path(input)
    output_path = project.path <> output
    Mix.Generator.copy_file(input_path, output_path)
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
