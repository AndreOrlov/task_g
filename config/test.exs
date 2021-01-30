import Config

config :geo_tasks, GeoTasks.Repo,
  username: "postgres",
  password: "postgres",
  database: "geo_tasks_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn
