defmodule GeoTasks.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_tasks,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
    ]
  end
end
