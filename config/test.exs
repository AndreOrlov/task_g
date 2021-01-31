import Config

config :geo_tasks, GeoTasks.Repo,
  username: "postgres",
  password: "postgres",
  database: "geo_tasks_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn

config :geo_tasks, :auth,
  key: "B77HkzbEY27hp/R5defbSBqTJpO3gjGoRQlcgPAvuZ43UC5YDiBmIj3LBL62XM+I",
  salt: "BVbV5Vfhqj3Xp4iQ+dY7UwP/5Szn1sNz"
