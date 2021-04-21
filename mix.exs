defmodule Sise.MixProject do
  use Mix.Project

  @version "0.9.3"
  @repo_url "https://github.com/aytchell/sise"

  def project do
    [
      app: :sise,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: @repo_url,

      # Hex
      description: "A simple to use SSDP client",
      package: package(),
      name: "Sise",
      docs: [
        main: "Sise",
        authors: ["Hannes Lerchl"],
        extras: ["LICENSE.txt", "Changelog.md"],
        source_ref: "releases/#{@version}"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Sise.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.24.0", only: :dev, runtime: false}
    ]
  end

  # Metadata for the Hex package repository
  defp package do
    [
      name: "sise",
      licenses: ["Apache-2.0"],
      maintainers: ["Hannes Lerchl"],
      links: %{"Github" => @repo_url}
    ]
  end
end
