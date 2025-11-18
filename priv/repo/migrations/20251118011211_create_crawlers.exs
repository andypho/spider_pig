defmodule SpiderPig.Repo.Migrations.CreateCrawlers do
  use Ecto.Migration

  def change do
    create table(:crawlers) do
      add :name, :string
      add :url, :string

      timestamps(type: :utc_datetime)
    end

    create table(:nodes) do
      add :name, :string
      add :crawler_id, references(:crawlers)

      timestamps(type: :utc_datetime)
    end

    create table(:edges) do
      add :source_id, references(:nodes)
      add :target_id, references(:nodes)

      timestamps(type: :utc_datetime)
    end

    create table(:extraction_strategies) do
      add :node_id, references(:nodes)
      add :type, :string

      timestamps(type: :utc_datetime)
    end

    create table(:extraction_strategy_schemas) do
      add :extraction_strategy_id, references(:extraction_strategies)
      add :data, :map
    end
  end
end
