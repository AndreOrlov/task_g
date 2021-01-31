defmodule GeoTasks.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_tasks,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
    ]
  end

  def application do
    [
      extra_applications: [:logger, :plug],
      mod: {GeoTasks.Application, []}
    ]
  end

  defp deps do
    [
      # code climate
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},

      # HTTP endpoint
      # We don't need Phoenix for a simple API
      {:plug_cowboy, "~> 2.4"},
      {:jason, "~> 1.2"},
      # NOTE: remove this if CORS protection is not necessary
      {:cors_plug, "~> 2.0"},

      # database
      {:ecto_sql, "~> 3.5"},
      {:postgrex, "~> 0.15"},

      # geo stuff
      {:geohash, "~> 1.2"},

      # crypto
      {:blake2_elixir, "~> 0.8"},
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
