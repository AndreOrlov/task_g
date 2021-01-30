defmodule GeoTasks.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :geo_tasks,
    adapter: Ecto.Adapters.Postgres
end
