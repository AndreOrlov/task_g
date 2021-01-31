defmodule GeoTasks.Endpoint do
  @moduledoc false

  use Plug.Router
  use Plug.ErrorHandler

  plug Plug.Logger
  # NOTE: remove this if CORS protection is not necessary
  plug CORSPlug
  plug :match
  plug :dispatch

  forward "/api/v1", to: GeoTasks.Router

  if Code.ensure_loaded?(Mix) and Mix.env() in ~w[dev test]a do
    @dialyzer :no_return

    get "/token/:role" do
      {:ok, token} = GeoTasks.Auth.sign(%{role: conn.params["role"], id: Ecto.UUID.generate()})
      conn |> send_resp(200, token) |> halt()
    end
  end

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
