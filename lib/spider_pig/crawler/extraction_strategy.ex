defmodule SpiderPig.Crawler.ExtractionStrategy do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler
  }

  @strategies [
    json_css_extraction_strategy: "JsonCssExtractionStrategy"
  ]

  schema "extraction_strategies" do
    belongs_to :node, Crawler.Node

    field :type, Ecto.Enum, values: @strategies
    has_many :schemas, Crawler.ExtractionStrategy.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [:type])
    |> validate_required([:type])
  end

  @spec get_all_type() :: list(String.t())
  def get_all_type() do
    Keyword.values(@strategies)
  end
end
