defmodule Griffin.MixProject do
  use Mix.Project

  @version "0.3.0"
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
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
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
      {:earmark, "~> 1.4"},
      {:file_system, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:plug_live_reload, "~> 0.2"},
      {:slugify, "~> 1.3"},
      {:yaml_elixir, "~> 2.9"},

      # dev dependencies
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:makeup_html, "~> 0.1", only: :dev, runtime: false},

      # test dependencies
      {:assertions, "~> 0.19"},

      # dev and test dependencies
      {:credo, "~> 1.7.2-rc.2", only: [:dev, :test], runtime: false}
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
      "guides/getting_started/quick_start.md",
      "guides/getting_started/core_concepts.md",
      "guides/working_with_templates/adding_js_css_fonts.md",
      "guides/working_with_templates/layouts.md",
      "guides/working_with_templates/collections.md",
      "guides/working_with_templates/content_dates.md",
      "guides/working_with_templates/permalinks.md",
      "guides/architecture/build_process.md",
      "guides/using_data/data_cascade.md"
    ]
  end

  defp groups_for_extras do
    [
      "Why Griffin?": ~r/guides\/why_griffin\/.?/,
      "Getting Started": ~r/guides\/getting_started\/.?/,
      "Working with Templates": ~r/guides\/working_with_templates\/.?/,
      "Using Data": ~r/guides\/using_data\/.?/,
      Architecture: ~r/guides\/architecture\/.?/
    ]
  end

  defp aliases do
    [
      "archive.build": &raise_on_archive_build/1,
      lint: ["format", "credo"]
    ]
  end

  defp raise_on_archive_build(_) do
    Mix.raise("""
    You are trying to install "griffin_ssg" as an archive, which is not supported. \
    You probably meant to install "grf_new" instead
    """)
  end
end
