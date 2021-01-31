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

config :geo_tasks, :auth,
  # 48 |> :crypto.strong_rand_bytes() |> Base.encode64()
  key: "WOlk7p/G6kg9AGtOqn5axjpJh/I0WopLuPYk36JOVD+c8++bwTdtm0gtZWqX8s62",
  # 24 |> :crypto.strong_rand_bytes() |> Base.encode64()
  salt: "MeB+sFbEv2TtPGTXsNBGInhnuVSm2SkQ"
