defmodule SpiderPig.Repo.Migrations.CreateCrawlers do
  use Ecto.Migration

  def change do
    create table(:crawlers) do
      add :name, :string, null: false
      add :url, :string, null: false
      add :cron, :string, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:browser_configs) do
      add :crawler_id, references(:crawlers, on_delete: :delete_all)

      add :headless, :boolean, default: true
      add :headers, :map
      add :extra_args, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create table(:nodes) do
      add :name, :string, null: false
      add :crawler_id, references(:crawlers, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create table(:edges) do
      add :source_id, references(:nodes)
      add :target_id, references(:nodes)

      timestamps(type: :utc_datetime)
    end

    create table(:extraction_strategies) do
      add :node_id, references(:nodes, on_delete: :delete_all)
      add :type, :string

      timestamps(type: :utc_datetime)
    end

    create table(:extraction_strategy_schemas) do
      add :extraction_strategy_id, references(:extraction_strategies, on_delete: :delete_all)

      add :name, :string, null: false
      add :type, :string, null: false
      add :base_selector, :string
      add :fields, {:array, :map}, default: []
    end
  end
end
