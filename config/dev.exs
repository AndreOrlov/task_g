import Config

config :geo_tasks, GeoTasks.Repo,
  username: "postgres",
  password: "postgres",
  database: "geo_tasks_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# NOTE: remove this if CORS protection is not necessary
config :cors_plug,
  origin: ["http://localhost"]

config :logger, :console, format: "[$level] $message\n"
