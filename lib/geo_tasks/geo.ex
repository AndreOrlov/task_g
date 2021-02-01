defmodule GeoTasks.Geo do
  @moduledoc """
  Geo related functions
  """

  @precisions [
    {0.074,     11},
    {0.6,       10},
    {2.4,       9},
    {19,        8},
    {76,        7},
    {610,       6},
    {2_400,     5},
    {20_000,    4},
    {78_000,    3},
    {630_000,   2},
    {2_500_000, 1},
  ]
  @to_rad :math.pi() / 180
  @earth_radius 6_371_000

  @doc """
  Finds a list of geo hashes for specified radius around point
  """
  @spec hashes_for_radius(lat :: float, lon :: float, radius :: float) :: [binary]
  def hashes_for_radius(lat, lon, radius) do
    precision =
      case Enum.find(@precisions, fn {r, _} -> r >= radius end) do
        {_, precision} -> precision
        _              -> 16
      end
    center = Geohash.encode(lat, lon, precision)
    neighbors = Geohash.neighbors(center)
    [center | Map.values(neighbors)]
  end

  # REVIEW: А Postgres нельзя заюзать. Ьыстрее должно быть.
  @doc """
  Finds distance in meters between two points

  See: https://www.movable-type.co.uk/scripts/latlong.html
  """
  @spec distance(lat1 :: float, lon1 :: float, lat2 :: float, lon2 :: float) :: float
  def distance(lat1, lon1, lat2, lon2) do
    diff_lat = (lat2 - lat1) * @to_rad
    diff_lon = (lon2 - lon1) * @to_rad
    sin_lat = :math.sin(diff_lat / 2)
    sin_lon = :math.sin(diff_lon / 2)
    a = sin_lat * sin_lat + :math.cos(lat1 * @to_rad) * :math.cos(lat2 * @to_rad) * sin_lon * sin_lon
    2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a)) * @earth_radius
  end
end
