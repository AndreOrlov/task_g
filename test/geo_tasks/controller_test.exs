defmodule GeoTasks.ControllerTest do
  alias GeoTasks.Controller
  alias GeoTasks.Controller.ServerErrorException

  use ExUnit.Case, async: true
  use Plug.Test
  use Controller

  def func1(_), do: :ok
  def func2(_), do: {:ok, [%{some: "json"}]}
  def func3(_), do: {:error, :reason}
  def func4(_), do: :unexpected
  def func5(conn), do: conn |> Plug.Conn.send_resp(500, "error")

  defp test_conn, do: conn(:post, "/")

  describe "handle_request/2" do
    test "handles :ok replies with 200 status" do
      conn = handle_request(:func1, test_conn())
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "handles {:ok, msg} replies with 200 status and JSON-encoded msg" do
      conn = handle_request(:func2, test_conn())
      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body == Jason.encode!([%{some: "json"}])
    end

    test "raises ServerErrorException {:error, reason} replies" do
      assert_raise ServerErrorException, fn -> handle_request(:func3, test_conn()) end
    end

    test "raises ServerErrorException on unexpected replies" do
      assert_raise ServerErrorException, fn -> handle_request(:func4, test_conn()) end
    end

    test "passes through %PlugConn{} replies" do
      conn = handle_request(:func5, test_conn())
      assert conn.status == 500
      assert conn.resp_body == "error"
    end
  end
end
