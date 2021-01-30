defmodule GeoTasks.Application do
  @moduledoc false

  use Application

  @app :geo_tasks

  @impl true
  def start(_type, _args) do
    children = [
      GeoTasks.Repo,
      endpoint_spec(),
    ]

    opts = [strategy: :one_for_one, name: GeoTasks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp endpoint_spec do
    {plug_opts, endpoint_opts} =
      @app
      |> Application.get_env(:endpoint, [])
      |> Keyword.split(~w[port]a)
    plug_opts =
      plug_opts
      |> Keyword.put_new(:port, 4000)
    endpoint_opts =
      endpoint_opts
      |> Keyword.put_new(:scheme, :http)
      |> Keyword.put(:plug, GeoTasks.Endpoint)
      |> Keyword.put(:options, plug_opts)

    {Plug.Cowboy, endpoint_opts}
  end
end
