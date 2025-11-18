defmodule SpiderPig.Crawler.ExtractionStrategy.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler
  }

  schema "extraction_strategy_schemas" do
    belongs_to :extraction_strategy, Crawler.ExtractionStrategy
    field :data, :map
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [:data])
    |> validate_required([:data])
  end
end
