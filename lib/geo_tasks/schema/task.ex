defmodule GeoTasks.Schema.Task do
  @moduledoc """
  Ecto task schema
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "tasks" do
    field :status, :string, default: "new"
    # REVIEW: User не хватает. Но, возможно, этого не было в задании
    field :manager_id, :binary_id
    field :driver_id, :binary_id

    # NOTE: these coordinates are for reference only
    # real search for distance done via pickup_geohash field
    field :pickup_lat, :decimal
    field :pickup_lon, :decimal
    field :delivery_lat, :decimal
    field :delivery_lon, :decimal

    field :pickup_geohash, :string

    timestamps()
  end

  @required_fields ~w[manager_id pickup_lat pickup_lon delivery_lat delivery_lon]a
  @optional_fields ~w[status driver_id]a
  @statuses ~w[new assigned done]
  @default_nearest_radius 1_000

  @spec create_changeset(task :: %__MODULE__{}, attrs :: map | keyword) :: Ecto.Changeset.t
  def create_changeset(task, attrs) do
    task
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, @statuses)
    |> validate_lat(:pickup_lat)
    |> validate_lon(:pickup_lon)
    |> validate_lat(:delivery_lat)
    |> validate_lon(:delivery_lon)
    |> put_geohash(:pickup_lat, :pickup_lon, :pickup_geohash)
  end

  @spec update_changeset(task :: %__MODULE__{}, attrs :: map | keyword) :: Ecto.Changeset.t
  def update_changeset(task, attrs) do
    task
    |> cast(attrs, ~w[status driver_id]a)
    |> validate_inclusion(:status, @statuses)
  end

  @spec nearest(lat :: float, lat :: float, opts :: keyword) :: Ecto.Query.t
  def nearest(lat, lon, opts \\ []) do
    radius = Keyword.get(opts, :radius, @default_nearest_radius)
    [h |_] = hashes = GeoTasks.Geo.hashes_for_radius(lat, lon, radius)
    precision = byte_size(h)
    query =
      from t in __MODULE__,
        where: t.status == "new",
        where: fragment("LEFT(?,?)", t.pickup_geohash, ^precision) in ^hashes

    case Keyword.get(opts, :limit) do
      limit when is_integer(limit) and limit > 0 ->
        from t in query, limit: ^limit

      _ ->
        query
    end
  end

  defp validate_lat(changeset, field) do
    case fetch_change(changeset, field) do
      {:ok, %Decimal{} = value} ->
        if Decimal.lt?(value, -90) or Decimal.gt?(value, 90) do
          add_error(changeset, field, "Latitude should be between -90 and 90")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_lon(changeset, field) do
    case fetch_change(changeset, field) do
      {:ok, %Decimal{} = value} ->
        if Decimal.lt?(value, -90) or Decimal.gt?(value, 90) do
          add_error(changeset, field, "Longitude should be between -180 and 180")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp put_geohash(changeset, lat_field, lon_field, hash_field) do
    with %Decimal{} = lat <- get_field(changeset, lat_field),
         %Decimal{} = lon <- get_field(changeset, lon_field) do
      hash = Geohash.encode(Decimal.to_float(lat), Decimal.to_float(lon), 11)
      put_change(changeset, hash_field, hash)
    else
      _ -> add_error(changeset, hash_field, "Geohash couldn't be calculated")
    end
  end
end
