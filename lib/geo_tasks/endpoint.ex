defmodule GeoTasks.Endpoint do
  @moduledoc false

  use Plug.Router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug :dispatch

  # NOTE: remove this if CORS protection is not necessary
  plug CORSPlug

  forward "/api/v1", to: GeoTasks.Router

  match _, do: send_error(conn)

  @doc """
  Sends error to the client
  """
  @spec send_error(conn :: Plug.Conn.t) :: Plug.Conn.t
  def send_error(conn) do
    # Do not provide sensitive info to hackers.
    # Always response with 400 status and empty explanation.
    conn |> send_resp(400, "") |> halt()
  end

  # Plug.ErrorHandler callback
  @doc false
  def handle_errors(conn, _error_info), do: send_error(conn)
end
