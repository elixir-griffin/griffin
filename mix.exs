defmodule Griffin.MixProject do
  use Mix.Project

  @version "0.2.0"
  @scm_url "https://github.com/elixir-griffin/griffin"

  def project do
    [
      app: :griffin_ssg,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Griffin",
      description: "Griffin static site generator",
      source_url: @scm_url,
      homepage_url: @scm_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      package: package(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:docs), do: ["lib", "installer/lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GriffinSSGApp, []},
      extra_applications: [:logger, :eex],
      env: [
        browser_open: false
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Gonçalo Tomás"],
      licenses: ["MIT"],
      links: %{"GitHub" => @scm_url},
      files: ~w(lib priv LICENSE.md mix.exs README.md .formatter.exs)
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yaml_elixir, "~> 2.9"},
      {:earmark, "~> 1.4"},
      {:plug_cowboy, "~> 2.5"},

      # docs dependencies
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "overview",
      logo: "logo.png",
      extra_section: "GUIDES",
      assets: "guides/assets",
      formatters: ["html", "epub"],
      # groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp extras do
    [
      "guides/why_griffin/overview.md",
      "guides/why_griffin/glossary.md",
      "guides/getting_started/getting_started.md",
      "guides/working_with_templates/adding_js_css_fonts.md",
      "guides/working_with_templates/layouts.md",
      "guides/working_with_templates/collections.md",
      "guides/working_with_templates/pagination.md",
      "guides/working_with_templates/permalinks.md"
    ]
  end

  defp groups_for_extras do
    [
      "Why Griffin?": ~r/guides\/why_griffin\/.?/,
      "Getting Started": ~r/guides\/getting_started\/.?/,
      "Working with Templates": ~r/guides\/working_with_templates\/.?/
    ]
  end

  defp aliases do
    [
      "archive.build": &raise_on_archive_build/1
    ]
  end

  defp raise_on_archive_build(_) do
    Mix.raise("""
    You are trying to install "griffin_ssg" as an archive, which is not supported. \
    You probably meant to install "grf_new" instead
    """)
  end
end
