defmodule GeoTasks.Controller do
  @moduledoc """
  Basic module for all controllers. Implements minimal abstraction logic
  """

  defmodule ServerErrorException do
    @moduledoc """
    The request will not be processed due to server error
    """

    defexception [
      message: "could not process the request due to server error",
      plug_status: 500,
      reason: nil,
    ]
  end

  @doc false
  defmacro __using__(_opts) do
    quote do
      def handle_request(action, conn) do
        unquote(__MODULE__).handle_request(__MODULE__, action, conn)
      end
    end
  end

  @doc false
  @spec handle_request(module :: module, action :: atom, conn :: Plug.Conn.t) :: Plug.Conn.t
  def handle_request(module, action, conn) when is_atom(module) and is_atom(action) do
    if function_exported?(module, action, 1) do
      case apply(module, action, [conn]) do
        :ok                 -> conn |> Plug.Conn.send_resp(200, "")
        {:ok, reply}        -> conn |> Plug.Conn.send_resp(200, Jason.encode!(reply))
        {:error, reason}    -> raise ServerErrorException, reason: reason
        %Plug.Conn{} = conn -> conn
        _                   -> raise ServerErrorException, message: "unexpected return value"
      end
    else
      raise ServerErrorException, message: "invalid controller action"
    end
  end
  def handle_request(_action, _conn) do
    raise ServerErrorException, message: "invalid controller action"
  end
end
