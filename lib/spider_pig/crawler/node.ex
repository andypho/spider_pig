defmodule SpiderPig.Crawler.Node do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler,
    Repo
  }

  @type t :: %__MODULE__{}

  schema "nodes" do
    field :name, :string
    belongs_to :crawler, Crawler

    has_one :extraction_strategy, Crawler.ExtractionStrategy
    has_many :edges, Crawler.Edge, foreign_key: :source_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [:name])
    |> validate_required([:name])
    |> cast_assoc(:extraction_strategy)
  end

  @doc """
  Convert to standard format for Crawl4Ai
  """
  @spec to_standard_format(t()) :: map
  def to_standard_format(%__MODULE__{} = struct) do
    struct = Repo.preload(struct, extraction_strategy: [:schema])
    extraction_strategy_schema = struct.extraction_strategy.schema

    schema = %{
      "type" => extraction_strategy_schema.type,
      "value" => %{
        "name" => extraction_strategy_schema.name,
        "baseSelector" => extraction_strategy_schema.base_selector,
        "fields" => Crawler.ExtractionStrategy.FieldsType.dump!(extraction_strategy_schema.fields)
      }
    }

    %{
      "type" => "CrawlerRunConfig",
      "params" => %{
        "extraction_strategy" => %{
          "type" => Crawler.ExtractionStrategy.type_to_string(struct.extraction_strategy.type),
          "params" => %{
            "schema" => schema
          }
        }
      }
    }
  end
end
