defmodule GeoTasks.ReleaseTasks do
  @moduledoc """
  Usable tasks for release
  """

  alias GeoTasks.Repo

  def migrate do
    run_migrations()
  end

  def seed do
    seeds = priv_path_for(Repo, "seeds.exs")
    if File.exists?(seeds) do
      run_migrations()
      Code.eval_file(seeds)
    end
  end

  defp run_migrations do
    app = Keyword.get(Repo.config(), :otp_app)
    IO.puts("Running migrations for #{app}")
    migrations_path = priv_path_for(Repo, "migrations")
    Ecto.Migrator.run(Repo, migrations_path, :up, all: true)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config(), :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"
    Path.join([priv_dir, repo_underscore, filename])
  end
end
