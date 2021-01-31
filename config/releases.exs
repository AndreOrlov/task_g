import Config

config :geo_tasks, GeoTasks.Repo,
  username: System.fetch_env!("DB_USERNAME"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10"))

# NOTE: remove this if CORS protection is not necessary
config :cors_plug,
  origin: String.split(System.fetch_env!("CORS_ORIGIN"), ~r/\s+/)

config :geo_tasks, :auth,
  # 48 |> :crypto.strong_rand_bytes() |> Base.encode64()
  key: System.fetch_env!("AUTH_KEY"),
  # 24 |> :crypto.strong_rand_bytes() |> Base.encode64()
  salt: System.fetch_env!("AUTH_SALT")
