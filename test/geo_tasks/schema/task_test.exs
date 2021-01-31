defmodule GeoTasks.Schema.TaskTest do
  use GeoTasks.DataCase, async: true

  alias GeoTasks.Schema.Task

  import Ecto.Changeset
  import Task
  import GeoTasks.Factory

  @valid_params %{
    pickup_lat: 54.630050,
    pickup_lon: 39.732979,
    delivery_lat: 54.630138,
    delivery_lon: 39.724679,
  }

  def valid_params, do: @valid_params |> Map.put(:manager_id, Ecto.UUID.generate())
  def valid_params(%{} = params), do: Map.merge(valid_params(), params)

  describe "create_changeset/2" do
    test "puts pickup geohash into changeset" do
      changeset = create_changeset(%Task{}, valid_params())
      assert changeset.valid?
      assert changeset |> get_change(:pickup_geohash) == Geohash.encode(54.630050, 39.732979, 11)
    end

    test "forbids changes without required fields" do
      params = valid_params()
      params
      |> Map.keys()
      |> Enum.each(fn key ->
        changeset = create_changeset(%Task{}, Map.delete(params, key))
        refute changeset.valid?
      end)
    end

    test "validates status" do
      changeset = create_changeset(%Task{}, valid_params(%{status: "test"}))
      refute changeset.valid?
    end

    test "validates geo points" do
      changeset = create_changeset(%Task{}, valid_params(%{pickup_lat: 100.0}))
      refute changeset.valid?

      changeset = create_changeset(%Task{}, valid_params(%{pickup_lon: 200.0}))
      refute changeset.valid?

      changeset = create_changeset(%Task{}, valid_params(%{delivery_lat: 100.0}))
      refute changeset.valid?

      changeset = create_changeset(%Task{}, valid_params(%{delivery_lon: 200.0}))
      refute changeset.valid?
    end
  end

  describe "update_changeset/2" do
    test "validates status" do
      changeset = update_changeset(%Task{}, valid_params(%{status: "test"}))
      refute changeset.valid?
    end
  end

  describe "nearest/2" do
    test "gets nearest tasks by geo hash" do
      t1 = insert!(:task, pickup_lat: 54.630050, pickup_lon: 39.732979)
      t2 = insert!(:task, pickup_lat: 54.630138, pickup_lon: 39.724679) # 500 meters
      insert!(:task, pickup_lat: 54.632270, pickup_lon: 39.759884) # 4 kilometers

      list = Repo.all(nearest(54.630050, 39.732979, radius: 600))

      assert length(list) == 2
      assert Enum.find(list, & &1.id == t1.id)
      assert Enum.find(list, & &1.id == t2.id)
    end

    test "limits task list" do
      insert!(:task, pickup_lat: 54.630050, pickup_lon: 39.732979)
      insert!(:task, pickup_lat: 54.630138, pickup_lon: 39.724679) # 500 meters
      insert!(:task, pickup_lat: 54.632270, pickup_lon: 39.759884) # 4 kilometers

      list = Repo.all(nearest(54.630050, 39.732979, radius: 600, limit: 1))

      assert length(list) == 1
    end
  end
end
