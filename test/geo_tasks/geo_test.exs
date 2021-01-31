defmodule GeoTasks.GeoTest do
  use ExUnit.Case, async: true

  import GeoTasks.Geo

  describe "distance/4" do
    test "calculates distance" do
      d = distance(54.630050, 39.732979, 54.630138, 39.724679)
      assert d >= 530 and d <= 540

      d = distance(54.615105, 39.706299, 54.632270, 39.759884)
      assert d >= 3900 and d <= 4000
    end
  end

  describe "hashes_for_radius/3" do
    test "finds hashes for radius with right precision" do
      hashes = hashes_for_radius(54.630050, 39.732979, 100_000)
      assert length(hashes) == 9
      assert Enum.all?(hashes, & byte_size(&1) == 2)

      hashes = hashes_for_radius(54.630050, 39.732979, 10_000)
      assert length(hashes) == 9
      assert Enum.all?(hashes, & byte_size(&1) == 4)
    end
  end
end
