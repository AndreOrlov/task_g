defmodule GeoTasks.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  import ExUnit.Assertions

  using do
    quote do
      alias GeoTasks.Endpoint
      import Plug.Conn
      import unquote(__MODULE__), only: [assert_conn: 2, assert_conn: 3]
      use Plug.Test

      def call(conn) do
        Endpoint.call(conn, Endpoint.init([]))
      end

      def authorize(conn, role, id) do
        {:ok, token} = GeoTasks.Auth.sign(%{role: role, id: id})
        conn |> put_req_header("authorization", token)
      end
      def authorize(conn, role) do
        authorize(conn, role, Ecto.UUID.generate())
      end
    end
  end

  setup tags do
    :ok = Sandbox.checkout(GeoTasks.Repo)

    unless tags[:async] do
      Sandbox.mode(GeoTasks.Repo, {:shared, self()})
    end

    :ok
  end

  def assert_conn(conn, %{} = opts) do
    case Map.get(opts, :status) do
      nil     -> :ok
      status  -> assert conn.status == status
    end

    case Map.get(opts, :resp) do
      nil                       -> :ok
      resp when is_binary(resp) -> assert conn.resp_body == resp
      %Regex{} = resp           -> assert Regex.match?(resp, conn.resp_body)
    end

    conn
  end
  def assert_conn(conn, opts) when is_list(opts), do: assert_conn(conn, Enum.into(opts, %{}))
  def assert_conn(conn, status) when is_integer(status), do: assert_conn(conn, %{status: status})
  def assert_conn(conn, resp), do: assert_conn(conn, %{resp: resp})

  def assert_conn(conn, status, resp), do: assert_conn(conn, %{status: status, resp: resp})
end
