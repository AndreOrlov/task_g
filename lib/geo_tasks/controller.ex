defmodule GeoTasks.Controller do
  @moduledoc """
  Basic module for all controllers. Implements minimal abstraction logic
  """

  alias GeoTasks.Endpoint

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
      import unquote(__MODULE__), only: [serialize: 1]
      import Plug.Conn

      def handle_request(action, conn) do
        unquote(__MODULE__).handle_request(__MODULE__, action, conn)
      end
    end
  end

  # REVIEW: Думаю избыточно. Макросы многих пугают. И с ходу прочитать код сложнее. Надо в макрос лезть.
  # REVIEW: Документации к функции не хватает.
  @doc false
  @spec handle_request(module :: module, action :: atom, conn :: Plug.Conn.t) :: Plug.Conn.t
  def handle_request(module, action, conn) when is_atom(module) and is_atom(action) do
    if function_exported?(module, action, 1) do
      case apply(module, action, [conn]) do
        :ok                 -> conn |> Plug.Conn.send_resp(200, "")
        {:ok, reply}        -> conn |> Plug.Conn.send_resp(200, Jason.encode!(reply))
        %Plug.Conn{} = conn -> conn
        _                   -> Endpoint.send_error(conn)
      end
    else
      raise ServerErrorException, message: "invalid controller action"
    end
  end
  def handle_request(_action, _conn) do
    raise ServerErrorException, message: "invalid controller action"
  end

  @spec serialize(any) :: any
  def serialize(%Decimal{} = value), do: Decimal.to_float(value)
  def serialize(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  def serialize(%_module{} = value), do: value |> Map.from_struct() |> serialize()
  def serialize(%{__meta__: _} = value), do: value |> Map.drop([:__meta__]) |> serialize()
  def serialize(%{} = value), do: value |> Enum.into(%{}, fn {k, v} -> {k, serialize(v)} end)
  def serialize(value) when is_list(value), do: Enum.map(value, &serialize/1)
  def serialize(value), do: value
end
