defmodule GeoTasks.Auth do
  @moduledoc """
  Authentication stuff
  """

  defmodule Plug do
    @moduledoc """
    Authentication plug
    """

    @behaviour Elixir.Plug
    alias Elixir.Plug.Conn

    @impl true
    def init(opts) do
      %{max_age: Keyword.get(opts, :max_age, 3_600)}
    end

    @impl true
    def call(conn, auth_config) do
      case Conn.get_req_header(conn, "authorization") do
        [token | _] when is_binary(token) ->
          token
          |> GeoTasks.Auth.verify(auth_config)
          |> case do
            {:ok, user} -> Conn.assign(conn, :user, user)
            _           -> conn
          end

        _ ->
          conn
      end
    end
  end

  alias Blake2.Blake2b
  use Bitwise

  # Needed for startup configuration in supervision tree
  @doc false
  @spec child_spec(keyword) :: Supervisor.child_spec
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :init, [opts]}
    }
  end

  # Needed for startup configuration in supervision tree
  @doc false
  @spec init(keyword) :: :ignore
  def init(opts) do
    config = %{
      key: Keyword.fetch!(opts, :key),
      salt: Keyword.fetch!(opts, :salt),
    }
    :persistent_term.put(__MODULE__, config)
    # ensures that `:role` and `:id` atoms are in atom table
    _atom_table = ~w[role id]a
    :ignore
  end

  @doc """
  Calculates hash for input binary with blake2 algorithm
  """
  @spec hash(input :: binary) :: {:ok, binary} | {:error, any}
  @spec hash(input :: binary, config :: map) :: {:ok, binary} | {:error, any}
  def hash(input, config \\ %{})
  def hash(input, %{key: key, salt: salt}) do
    {:ok, Blake2b.hash(input, key, 64, salt)}
  end
  def hash(_, nil) do
    {:error, :auth_not_configured}
  end
  def hash(input, _) do
    hash(input, :persistent_term.get(__MODULE__))
  end

  @doc """
  Signs data and generates signed token
  """
  @spec sign(input :: any) :: {:ok, binary} | {:error, any}
  @spec sign(input :: any, config :: map) :: {:ok, binary} | {:error, any}
  def sign(data, config \\ %{}) do
    with {:ok, data} <- pack(%{data: data, signed: now_ms()}),
         {:ok, hash} <- hash(data, config) do
      {:ok, data <> "--" <> Base.encode64(hash)}
    end
  end

  @doc """
  Verifies signed data and token age
  """
  @spec verify(input :: binary) :: {:ok, any} | {:error, any}
  @spec verify(input :: binary, config :: map) :: {:ok, any} | {:error, any}
  def verify(data, config \\ %{}) do
    case String.split(data, "--", parts: 2) do
      [content, digest] when content != "" and digest != "" ->
        with {:ok, verify_digest} <- hash(content, config),
             true <- secure_compare(Base.encode64(verify_digest), digest),
             {:ok, %{data: data, signed: signed}} <- unpack(content) do
          if expired?(signed, config[:max_age]) do
            {:error, :expired}
          else
            {:ok, data}
          end
        else
          false -> {:error, :unverified}
          error -> error
        end

      _ ->
        {:error, :invalid_input}
    end
  end

  @doc """
  Packs data for signing
  """
  @spec pack(input :: any) :: {:ok, binary}
  def pack(data) do
    packed = data |> :erlang.term_to_binary() |> Base.encode64
    {:ok, packed}
  end

  @doc """
  Unpacks data for verifying
  """
  @spec unpack(input :: binary) :: {:ok, any} | {:error, :wrong_binary | :unpack_error}
  def unpack(data) do
    with {:ok, decoded} <- decode_base64(data),
         size = byte_size(decoded),
         {value, ^size} <- :erlang.binary_to_term(decoded, ~w[safe used]a) do
      {:ok, value}
    else
      _ -> {:error, :unpack_error}
    end
  end

  defp now_ms, do: System.system_time(:millisecond)

  defp decode_base64(x) when is_binary(x) do
    x |> pad_base64() |> Base.decode64()
  end
  defp decode_base64(_), do: {:error, :wrong_binary}

  defp pad_base64(x) when rem(byte_size(x), 4) > 0 do
    x <> String.pad_leading("", 4 - rem(byte_size(x), 4), "=")
  end
  defp pad_base64(x), do: x

  @doc """
  Compares the two binaries in constant-time to avoid timing attacks.

  See: http://codahale.com/a-lesson-in-timing-attacks/
  """
  @spec secure_compare(left :: binary, right :: binary) :: boolean
  def secure_compare(left, right) when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    secure_compare(left, right, 0)
  end
  def secure_compare(_left, _right), do: false

  defp secure_compare(<<x, left :: binary>>, <<y, right :: binary>>, acc) do
    xorred = x ^^^ y
    secure_compare(left, right, acc ||| xorred)
  end
  defp secure_compare(<<>>, <<>>, acc), do: acc === 0

  defp expired?(_signed, :infinity), do: false
  defp expired?(signed, nil), do: expired?(signed, 86_400) # default expired is 1 day
  defp expired?(_signed, max_age_secs) when max_age_secs <= 0, do: true
  defp expired?(signed, max_age_secs), do: (signed + trunc(max_age_secs * 1000)) < now_ms()
end
