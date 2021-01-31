defmodule GeoTasks.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :status, :string, size: 10, default: "new"
      add :manager_id, :uuid, null: false
      add :driver_id, :uuid

      # NOTE: these coordinates are for reference only
      # real search for distance done via pickup_geohash field
      add :pickup_lat, :decimal, precision: 9, scale: 6, null: false
      add :pickup_lon, :decimal, precision: 9, scale: 6, null: false
      add :delivery_lat, :decimal, precision: 9, scale: 6, null: false
      add :delivery_lon, :decimal, precision: 9, scale: 6, null: false

      add :pickup_geohash, :string, size: 11, null: false

      timestamps()
    end

    create index(:tasks, ~w[pickup_geohash]a)
  end
end
