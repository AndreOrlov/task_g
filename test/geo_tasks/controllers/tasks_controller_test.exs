defmodule GeoTasks.TasksControllerTest do
  use GeoTasks.ConnCase, async: true

  import GeoTasks.Factory

  @create_params %{
    pickup: %{lat: 54.630050, lon: 39.732979},
    delivery: %{lat: 54.630138, lon: 39.724679},
  }

  @nearest_params %{
    lat: 54.630050,
    lon: 39.732979,
  }

  describe "create/1" do
    test "authorized only for managers" do
      :post
      |> conn("/api/v1/tasks", @create_params)
      |> call()
      |> assert_conn(401, "Unauthorized")

      :post
      |> conn("/api/v1/tasks", @create_params)
      |> authorize("driver")
      |> call()
      |> assert_conn(401, "Unauthorized")
    end

    test "validates pickup parameter" do
      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[pickup lat]a, "test"))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid pickup point latitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[pickup lat]a, -91.3))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid pickup point latitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[pickup lon]a, "test"))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid pickup point longitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[pickup lon]a, 181.5))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid pickup point longitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[pickup]a, "test"))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid pickup point")
    end

    test "validates delivery parameter" do
      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[delivery lat]a, "test"))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid delivery point latitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[delivery lat]a, -91.3))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid delivery point latitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[delivery lon]a, "test"))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid delivery point longitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[delivery lon]a, 181.5))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid delivery point longitude")

      :post
      |> conn("/api/v1/tasks", put_in(@create_params, ~w[delivery]a, "test"))
      |> authorize("manager")
      |> call()
      |> assert_conn(400, "Invalid delivery point")
    end

    test "creates new task" do
      conn =
        :post
        |> conn("/api/v1/tasks", @create_params)
        |> authorize("manager")
        |> call()
        |> assert_conn(200)
      resp = Jason.decode!(conn.resp_body)
      task = get(:task, resp["id"])
      assert task.status == "new"
      assert task.pickup_geohash == Geohash.encode(@create_params.pickup.lat, @create_params.pickup.lon, 11)
    end
  end

  describe "list/1" do
    test "authorized only for drivers" do
      :post
      |> conn("/api/v1/tasks/nearest", @nearest_params)
      |> call()
      |> assert_conn(401, "Unauthorized")

      :post
      |> conn("/api/v1/tasks/nearest", @nearest_params)
      |> authorize("manager")
      |> call()
      |> assert_conn(401, "Unauthorized")
    end

    test "validates driver point" do
      :post
      |> conn("/api/v1/tasks/nearest", put_in(@nearest_params, ~w[lat]a, "test"))
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid driver point latitude")

      :post
      |> conn("/api/v1/tasks/nearest", put_in(@nearest_params, ~w[lat]a, -91.3))
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid driver point latitude")

      :post
      |> conn("/api/v1/tasks/nearest", put_in(@nearest_params, ~w[lon]a, "test"))
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid driver point longitude")

      :post
      |> conn("/api/v1/tasks/nearest", put_in(@nearest_params, ~w[lon]a, 181.5))
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid driver point longitude")

      :post
      |> conn("/api/v1/tasks/nearest", %{})
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid driver point")
    end

    test "returns list of nearest tasks ordered by distance" do
      insert!(:task, pickup_lat: 54.732270, pickup_lon: 39.759884) # > 4 kilometers
      t1 = insert!(:task, pickup_lat: 54.630138, pickup_lon: 39.724679) # 534 meters
      t2 = insert!(:task, pickup_lat: 54.630050, pickup_lon: 39.732979) # exact

      conn =
        :post
        |> conn("/api/v1/tasks/nearest", @nearest_params)
        |> authorize("driver")
        |> call()
        |> assert_conn(200)

      list = Jason.decode!(conn.resp_body)
      assert length(list) == 2
      assert Enum.at(list, 0)["id"] == t2.id
      assert Enum.at(list, 1)["id"] == t1.id
      assert_in_delta Enum.at(list, 0)["distance"], 0.0, 0.5
      assert_in_delta Enum.at(list, 1)["distance"], 534.0, 0.5
    end
  end

  describe "pickup/1" do
    test "authorized only for drivers" do
      t = insert!(:task)

      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: t.id})
      |> call()
      |> assert_conn(401, "Unauthorized")

      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: t.id})
      |> authorize("manager")
      |> call()
      |> assert_conn(401, "Unauthorized")
    end

    test "validates task_id" do
      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: "test"})
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid task id")
    end

    test "refuses inexistent tasks" do
      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: Ecto.UUID.generate()})
      |> authorize("driver")
      |> call()
      |> assert_conn(404, "Task not found")
    end

    test "refuses not newly created tasks" do
      t1 = insert!(:task, status: "assigned")
      t2 = insert!(:task, status: "done")

      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: t1.id})
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid task")

      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: t2.id})
      |> authorize("driver")
      |> call()
      |> assert_conn(400, "Invalid task")
    end

    test "sets task status to `assigned` and driver_id to authorized user id" do
      t = insert!(:task)
      driver_id = Ecto.UUID.generate()

      :post
      |> conn("/api/v1/tasks/pickup", %{task_id: t.id})
      |> authorize("driver", driver_id)
      |> call()
      |> assert_conn(200)

      assert %{status: "assigned", driver_id: ^driver_id} = get(:task, t.id)
    end
  end

  describe "finish/1" do
    test "authorized only for drivers how picked up the task" do
      t = insert!(:task, status: "assigned", driver_id: Ecto.UUID.generate())

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: t.id})
      |> call()
      |> assert_conn(401, "Unauthorized")

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: t.id})
      |> authorize("manager")
      |> call()
      |> assert_conn(401, "Unauthorized")

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: t.id})
      |> authorize("driver")
      |> call()
      |> assert_conn(401, "Unauthorized")
    end

    test "validates task_id" do
      t = insert!(:task, status: "assigned", driver_id: Ecto.UUID.generate())

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: "test"})
      |> authorize("driver", t.driver_id)
      |> call()
      |> assert_conn(400, "Invalid task id")
    end

    test "refuses inexistent tasks" do
      t = insert!(:task, status: "assigned", driver_id: Ecto.UUID.generate())

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: Ecto.UUID.generate()})
      |> authorize("driver", t.driver_id)
      |> call()
      |> assert_conn(404, "Task not found")
    end

    test "refuses not assigned tasks" do
      t1 = insert!(:task, status: "new", driver_id: Ecto.UUID.generate())
      t2 = insert!(:task, status: "done", driver_id: Ecto.UUID.generate())

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: t1.id})
      |> authorize("driver", t1.driver_id)
      |> call()
      |> assert_conn(400, "Invalid task")

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: t2.id})
      |> authorize("driver", t2.driver_id)
      |> call()
      |> assert_conn(400, "Invalid task")
    end

    test "sets task status to `done`" do
      t = insert!(:task, status: "assigned", driver_id: Ecto.UUID.generate())

      :post
      |> conn("/api/v1/tasks/finish", %{task_id: t.id})
      |> authorize("driver", t.driver_id)
      |> call()
      |> assert_conn(200)

      assert %{status: "done"} = get(:task, t.id)
    end
  end
end
