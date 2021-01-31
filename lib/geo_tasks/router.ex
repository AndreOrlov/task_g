defmodule GeoTasks.Router do
  @moduledoc false

  use Plug.Router

  alias GeoTasks.TasksController, as: Tasks

  plug GeoTasks.Auth.Plug
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason

  plug :match
  plug :dispatch

  post "/tasks", do: Tasks.handle_request(:create, conn)
  post "/tasks/nearest", do: Tasks.handle_request(:list, conn)
  post "/tasks/pickup", do: Tasks.handle_request(:pickup, conn)
  post "/tasks/finish", do: Tasks.handle_request(:finish, conn)

  match _, do: GeoTasks.Endpoint.send_error(conn)
end
