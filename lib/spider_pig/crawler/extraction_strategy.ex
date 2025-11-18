defmodule SpiderPig.Crawler.ExtractionStrategy do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler
  }

  @type t :: %__MODULE__{}

  @strategies [
    json_css_extraction_strategy: "JsonCssExtractionStrategy"
  ]

  schema "extraction_strategies" do
    belongs_to :node, Crawler.Node

    field :type, Ecto.Enum, values: @strategies
    has_one :schema, Crawler.ExtractionStrategy.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [:type])
    |> validate_required([:type])
    |> cast_assoc(:schema)
  end

  @spec get_all_type() :: list({atom(), String.t()})
  def get_all_type(), do: @strategies

  @spec type_to_string(atom()) :: String.t()
  def type_to_string(type) when is_atom(type), do: Keyword.get(@strategies, type)
end
