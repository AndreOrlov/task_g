import Config

config :geo_tasks,
  namespace: GeoTasks,
  ecto_repos: [GeoTasks.Repo],
  generators: [binary_id: true]

config :logger, :console,
  format: "$time $metadata[$level] $message\n"

import_config "#{Mix.env()}.exs"
