defmodule GeoTasks.TasksController do
  @moduledoc """
  Tasks controller
  """

  alias GeoTasks.Repo
  alias GeoTasks.Schema.Task

  use GeoTasks.Controller

  @nearest_radius 1_000
  @nearest_limit 100

  @doc """
  Creates task

  request:
    %{
      pickup: %{lat: 53.1, lon: 37.2},    # pickup point
      delivery: %{lat: 57.1, lon: 36.3},  # delivery point
    }

  response:
    %{
      id: "7b29f45d-b934-456f-9140-2b69a3b273fa", # task id
    }

  errors:

  * 400, "Invalid pickup point" - `pickup` parameter should be in form `%{lat: 53.1, lon: 37.2}`
  * 400, "Invalid pickup point latitude"
  * 400, "Invalid pickup point longitude"
  * 400, "Invalid delivery point" - `delivery` parameter should be in form `%{lat: 53.1, lon: 37.2}`
  * 400, "Invalid delivery point latitude"
  * 400, "Invalid delivery point longitude"
  * 401, "Unauthorized" - you are not authorized to create tasks
  """
  @spec create(conn :: Plug.Conn.t) :: {:ok, map} | Plug.Conn.t
  def create(%{params: params, assigns: %{user: %{role: "manager", id: manager_id}}} = conn) do
    with {:ok, params} <- sanitize_task(params, conn) do
      params = Map.put(params, :manager_id, manager_id)
      changeset = Task.create_changeset(%Task{}, params)
      task = Repo.insert!(changeset)
      {:ok, task |> Map.take(~w[id]a) |> serialize()}
    end
  end
  def create(conn) do
    send_error(conn, 401, "Unauthorized")
  end

  @doc """
  Returns a list of nearest tasks

  request:
    %{
      lat: 53.3, # drivers point latitude
      lon: 37.3, # drivers point longitude
    }

  response:
    [
      %{
        id: "7b29f45d-b934-456f-9140-2b69a3b273fa",         # task id
        manager_id: "9ab0e091-fa97-4cc8-ba1a-621ad93616ee", # manager id
        status: "assigned",                                 # status
        updated_at: "2021-01-31T10:38:25.884872",           # update timestamp
        pickup: %{lat: 53.1, lon: 37.2},                    # pickup point
        delivery: %{lat: 57.1, lon: 36.3},                  # delivery point
      },
      ...
    ]

  errors:

  * 401, "Unauthorized" - you are not authorized to get task list
  """
  @spec list(conn :: Plug.Conn.t) :: {:ok, [map]} | Plug.Conn.t
  def list(%{params: params, assigns: %{user: %{role: "driver"}}} = conn) do
    with {:ok, lat, lon} <- sanitize_geo_point(params, "driver point", conn) do
      query = Task.nearest(lat, lon, raidus: @nearest_radius, limit: @nearest_limit)
      list =
        query
        |> Repo.all()
        |> Enum.map(fn task ->
          pickup_lat = Decimal.to_float(task.pickup_lat)
          pickup_lon = Decimal.to_float(task.pickup_lon)

          task
          |> Map.take(~w[id status manager_id updated_at]a)
          |> Map.merge(%{
            pickup: %{lat: task.pickup_lat, lon: task.pickup_lon},
            delivery: %{lat: task.delivery_lat, lon: task.delivery_lon},
            distance: GeoTasks.Geo.distance(lat, lon, pickup_lat, pickup_lon),
          })
        end)
        |> Enum.sort_by(& &1.distance)
        |> serialize()
      {:ok, list}
    end
  end
  def list(conn) do
    send_error(conn, 401, "Unauthorized")
  end

  @doc """
  Marks specified task as picked up

  request:
    %{
      task_id: "7b29f45d-b934-456f-9140-2b69a3b273fa", # task id
    }

  response:
    %{
      id: "7b29f45d-b934-456f-9140-2b69a3b273fa", # task id
      status: "assigned",                         # new status
      updated_at: "2021-01-31T10:38:25.884872",   # update timestamp
    }

  errors:

  * 404, "Task not found" - where are no task with specified id
  * 400, "Invalid task id" - invalid task id parameter
  * 400, "Invalid task" - specified task has invalid status
  * 401, "Unauthorized" - you are not authorized to pick up task
  """
  @spec pickup(conn :: Plug.Conn.t) :: {:ok, map} | Plug.Conn.t
  def pickup(%{params: params, assigns: %{user: %{role: "driver", id: driver_id}}} = conn) do
    with {:ok, task_id} <- sanitize_task_id(params, conn),
         %Task{status: "new"} = task <- Repo.get(Task, task_id) do
      changeset = Task.update_changeset(task, %{status: "assigned", driver_id: driver_id})
      task = Repo.update!(changeset)
      {:ok, task |> Map.take(~w[id status updated_at]a) |> serialize()}
    else
      nil     -> send_error(conn, 404, "Task not found")
      %Task{} -> send_error(conn, "Invalid task")
      other   -> other
    end
  end
  def pickup(conn) do
    send_error(conn, 401, "Unauthorized")
  end

  @doc """
  Marks specified task as done

  request:
    %{
      task_id: "7b29f45d-b934-456f-9140-2b69a3b273fa", # task id
    }

  response:
    %{
      id: "7b29f45d-b934-456f-9140-2b69a3b273fa", # task id
      status: "done",                             # new status
      updated_at: "2021-01-31T10:38:25.884872",   # update timestamp
    }

  errors:

  * 404, "Task not found" - where are no task with specified id
  * 400, "Invalid task id" - invalid task id parameter
  * 400, "Invalid task" - specified task has invalid status
  * 401, "Unauthorized" - you are not authorized to finish this task
  """
  @spec finish(conn :: Plug.Conn.t) :: {:ok, map} | Plug.Conn.t
  def finish(%{params: params, assigns: %{user: %{role: "driver", id: driver_id}}} = conn) do
    with {:ok, task_id} <- sanitize_task_id(params, conn),
         %Task{status: "assigned", driver_id: ^driver_id} = task <- Repo.get(Task, task_id) do
      changeset = Task.update_changeset(task, %{status: "done"})
      task = Repo.update!(changeset)
      {:ok, task |> Map.take(~w[id status updated_at]a) |> serialize()}
    else
      nil                       -> send_error(conn, 404, "Task not found")
      %Task{status: "assigned"} -> send_error(conn, 401, "Unauthorized")
      %Task{}                   -> send_error(conn, "Invalid task")
      other                     -> other
    end
  end
  def finish(conn) do
    send_error(conn, 401, "Unauthorized")
  end

  defp send_error(conn, msg) do
    conn |> send_resp(400, msg) |> halt()
  end
  defp send_error(conn, status, msg) do
    conn |> send_resp(status, msg) |> halt()
  end

  defp sanitize_task(%{} = params, conn) do
    with {:p, {:ok, pickup}} <- {:p, Map.fetch(params, "pickup")},
         {:d, {:ok, delivery}} <- {:d, Map.fetch(params, "delivery")},
         {:ok, p_lat, p_lon} <- sanitize_geo_point(pickup, "pickup point", conn),
         {:ok, d_lat, d_lon} <- sanitize_geo_point(delivery, "delivery point", conn) do
      {:ok, %{
        pickup_lat: p_lat,
        pickup_lon: p_lon,
        delivery_lat: d_lat,
        delivery_lon: d_lon,
      }}
    else
      {:p, _} -> send_error(conn, "Invalid pickup point")
      {:d, _} -> send_error(conn, "Invalid delivery point")
      error   -> error
    end
  end
  defp sanitize_task(_, conn), do: send_error(conn, "Invalid task")

  defp sanitize_geo_point(%{"lat" => lat, "lon" => lon}, name, conn) when is_float(lat) and is_float(lon) do
    cond do
      lat < -90 or lat > 90   -> send_error(conn, "Invalid #{name} latitude")
      lon < -180 or lon > 180 -> send_error(conn, "Invalid #{name} longitude")
      true                    -> {:ok, lat, lon}
    end
  end
  defp sanitize_geo_point(%{"lon" => lon}, name, conn) when is_float(lon) do
    send_error(conn, "Invalid #{name} latitude")
  end
  defp sanitize_geo_point(%{"lat" => lat}, name, conn) when is_float(lat) do
    send_error(conn, "Invalid #{name} longitude")
  end
  defp sanitize_geo_point(_, name, conn), do: send_error(conn, "Invalid #{name}")

  defp sanitize_task_id(%{"task_id" => task_id}, conn) when is_binary(task_id) and byte_size(task_id) == 36 do
    case Ecto.UUID.cast(task_id) do
      {:ok, id} -> {:ok, id}
      _         -> send_error(conn, "Invalid task id")
    end
  end
  defp sanitize_task_id(_, conn), do: send_error(conn, "Invalid task id")
end
