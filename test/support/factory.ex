defmodule GeoTasks.Factory do
  @moduledoc false

  alias GeoTasks.Repo
  alias GeoTasks.Schema.Task

  def build(:task, attr) do
    task =
      %Task{
        status: "new",
        manager_id: Ecto.UUID.generate(),
        pickup_lat: 54.630050,
        pickup_lon: 39.732979,
        delivery_lat: 54.630138,
        delivery_lon: 39.724679,
      }
      |> struct!(attr)
    %{task | pickup_geohash: Geohash.encode(task.pickup_lat, task.pickup_lon, 11)}
  end

  def insert!(model, attr \\ []) do
    model |> build(attr) |> Repo.insert!()
  end

  def get(:task, id), do: Repo.get(Task, id)
end
