defmodule GeoTasks.Router do
  @moduledoc false

  use Plug.Router

  alias GeoTasks.TasksController, as: Tasks

  plug :match
  plug :dispatch

  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason

  post "/tasks", do: Tasks.handle_request(:create, conn)
  get  "/tasks", do: Tasks.handle_request(:list, conn)
  post "/tasks/:task_id/pick", do: Tasks.handle_request(:pick, conn)
  post "/tasks/:task_id/finish", do: Tasks.handle_request(:finish, conn)

  match _, do: GeoTasks.Endpoint.send_error(conn)
end
