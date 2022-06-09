defmodule Griffin.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/elixir-griffin/griffin"

  def project do
    [
      app: :griffin_ssg,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Griffin",
      description: "Griffin static site generator",
      source_url: @scm_url,
      homepage_url: @scm_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      package: package()
    ]
  end

  defp elixirc_paths(:docs), do: ["lib", "installer/lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GriffinSSG, []},
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
      {:ex_doc, "~> 0.28.4", only: :docs, runtime: false}
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
      "guides/introduction/overview.md",
      "guides/introduction/installation.md",
      "guides/introduction/up_and_running.md"
      # "guides/introduction/community.md",
      # "guides/directory_structure.md",
      # "guides/request_lifecycle.md",
      # "guides/plug.md",
      # "guides/routing.md",
      # "guides/controllers.md",
      # "guides/views.md",
      # "guides/ecto.md",
      # "guides/contexts.md",
      # "guides/mix_tasks.md",
      # "guides/telemetry.md",
      # "guides/asset_management.md",
      # "guides/authentication/mix_phx_gen_auth.md",
      # "guides/real_time/channels.md",
      # "guides/real_time/presence.md",
      # "guides/testing/testing.md",
      # "guides/testing/testing_contexts.md",
      # "guides/testing/testing_controllers.md",
      # "guides/testing/testing_channels.md",
      # "guides/deployment/deployment.md",
      # "guides/deployment/releases.md",
      # "guides/deployment/gigalixir.md",
      # "guides/deployment/fly.md",
      # "guides/deployment/heroku.md",
      # "guides/howto/custom_error_pages.md",
      # "guides/howto/using_ssl.md",
      # "CHANGELOG.md"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/guides\/introduction\/.?/,
      Guides: ~r/guides\/[^\/]+\.md/,
      Deployment: ~r/guides\/deployment\/.?/
    ]
  end
end
