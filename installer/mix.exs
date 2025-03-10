for path <- :code.get_path,
    Regex.match?(~r/grf_new\-\d+\.\d+\.\d\/ebin$/, List.to_string(path)) do
  Code.delete_path(path)
end

defmodule Grf.New.MixProject do
  use Mix.Project

  @version "0.3.1"
  @scm_url "https://github.com/elixir-griffin/griffin"

  # If the elixir requirement is updated, we need to update:
  #
  #   1. the mix.exs generated by the installer
  #   2. guides/introduction/installation.md
  #   3. test/test_helper.exs at the root
  #   4. installer/lib/mix/tasks/grf.new.ex
  #
  @elixir_requirement "~> 1.14"

  def project do
    [
      app: :grf_new,
      start_permanent: Mix.env() == :prod,
      version: @version,
      elixir: @elixir_requirement,
      deps: deps(),
      package: [
        maintainers: [
          "Gonçalo Tomás"
        ],
        licenses: ["MIT"],
        links: %{"GitHub" => @scm_url},
        files: ~w(lib priv mix.exs README.md)
      ],
      preferred_cli_env: [docs: :docs],
      source_url: @scm_url,
      docs: docs(),
      homepage_url: "https://github.com/elixir-griffin/griffin",
      description: """
      Griffin framework project generator.
      Provides a `mix grf.new` task to bootstrap a new Elixir application
      with Griffin dependencies and boilerplate code.
      """
    ]
  end

  def application do
    [
      extra_applications: [:eex]
    ]
  end

  def deps do
    [
      {:ex_doc, "~> 0.24", only: :docs}
    ]
  end

  defp docs do
    [
      source_url_pattern: "#{@scm_url}/blob/v#{@version}/installer/%{path}#L%{line}"
    ]
  end
end
