defmodule GeoTasks.AuthTest do
  use ExUnit.Case, async: true

  import GeoTasks.Auth

  describe "init/1" do
    test "ensures `:key` and `:salt` options are present" do
      assert_raise KeyError, fn -> init(salt: "") end
      assert_raise KeyError, fn -> init(key: "") end
    end

    test "puts auth config to persistent storage" do
      init(key: "key", salt: "salt")
      assert :persistent_term.get(GeoTasks.Auth) == %{key: "key", salt: "salt"}
    end
  end

  describe "hash/2" do
    test "takes config from persistent storage" do
      key = 48 |> :crypto.strong_rand_bytes() |> Base.encode64()
      salt = 24 |> :crypto.strong_rand_bytes() |> Base.encode64()
      :persistent_term.put(GeoTasks.Auth, %{key: key, salt: salt})
      assert hash("test") == {:ok, Blake2.Blake2b.hash("test", key, 64, salt)}
    end

    test "uses specified config" do
      key = 48 |> :crypto.strong_rand_bytes() |> Base.encode64()
      salt = 24 |> :crypto.strong_rand_bytes() |> Base.encode64()
      assert hash("test", %{key: key, salt: salt}) == {:ok, Blake2.Blake2b.hash("test", key, 64, salt)}
    end
  end

  describe "sign/2" do
    test "forms token as a term in ETF format that contains data and sign timestamp" do
      t_before = System.system_time(:millisecond)
      {:ok, token} = sign(%{some: "test"})
      t_after = System.system_time(:millisecond)
      [data_encoded, _sign] = String.split(token, "--")
      data = Base.decode64!(data_encoded)
      assert %{data: %{some: "test"}, signed: timestamp} = :erlang.binary_to_term(data)
      assert timestamp >= t_before and timestamp <= t_after
    end
  end

  describe "verify/2" do
    test "refuses expired tokens" do
      {:ok, token} = sign(%{test: "me"})
      Process.sleep(1001)
      assert verify(token, %{max_age: 1}) == {:error, :expired}
    end

    test "refuses tokens signed by wrong sign" do
      {:ok, t1} = sign(%{test: "me"})
      Process.sleep(1)
      {:ok, t2} = sign(%{test: "me"})
      [d, _] = String.split(t1, "--")
      [_, s] = String.split(t2, "--")
      assert verify(d <> "--" <> s) == {:error, :unverified}

      {:ok, t1} = sign(%{test: "me"})
      {:ok, t2} = sign(%{test: "them"})
      [d, _] = String.split(t1, "--")
      [_, s] = String.split(t2, "--")
      assert verify(d <> "--" <> s) == {:error, :unverified}
    end

    test "verifies signed token" do
      {:ok, token} = sign(%{test: "me"})
      assert verify(token) == {:ok, %{test: "me"}}
    end
  end

  describe "pack/1" do
    test "encodes values" do
      assert pack(%{my: "test"}) == {:ok, %{my: "test"} |> :erlang.term_to_binary() |> Base.encode64()}
    end
  end

  describe "unpack/1" do
    test "refuses terms with non-existent atoms" do
      # %{some_inexistent_atom: "test"} |> :erlang.term_to_binary() |> Base.encode64()
      x = "g3QAAAABZAAUc29tZV9pbmV4aXN0ZW50X2F0b21tAAAABHRlc3Q="
      assert_raise ArgumentError, fn -> unpack(x) end
    end

    test "decodes valid binaries" do
      x = %{some: "test"} |> :erlang.term_to_binary() |> Base.encode64()
      assert unpack(x) == {:ok, %{some: "test"}}
    end
  end

  describe "secure_compare/2" do
    test "compares two binaries" do
      refute secure_compare(<<1, 2, 3>>, <<1, 2>>)
      refute secure_compare(<<1, 2, 3>>, <<1, 2, 4>>)
      assert secure_compare(<<1, 2, 3>>, <<1, 2, 3>>)
    end
  end
end
