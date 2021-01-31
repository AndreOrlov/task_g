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
  def invalid_action(_, _), do: :ok

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

    test "returns 400 status for {:error, reason} replies" do
      conn = handle_request(:func3, test_conn())
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "returns 400 status on unexpected replies" do
      conn = handle_request(:func4, test_conn())
      assert conn.state == :sent
      assert conn.status == 400
      assert conn.resp_body == ""
    end

    test "passes through %PlugConn{} replies" do
      conn = handle_request(:func5, test_conn())
      assert conn.status == 500
      assert conn.resp_body == "error"
    end

    test "raises error for invalid actions" do
      assert_raise ServerErrorException, fn -> handle_request(:nonexistent_action, test_conn()) end
      assert_raise ServerErrorException, fn -> handle_request(:invalid_action, test_conn()) end
    end
  end
end
