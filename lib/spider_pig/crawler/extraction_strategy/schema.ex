defmodule SpiderPig.Crawler.ExtractionStrategy.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler,
    Crawler.ExtractionStrategy.FieldsType
  }

  @type t :: %__MODULE__{}

  schema "extraction_strategy_schemas" do
    belongs_to :extraction_strategy, Crawler.ExtractionStrategy

    field :name, :string
    field :type, :string, default: "dict"
    field :base_selector, :string
    field :fields, FieldsType, default: []
  end

  @optional_fields []
  @required_fields [:name, :type, :base_selector, :fields]

  @doc false
  def changeset(module, %{"fields" => fields} = params) when is_map(fields) do
    new_fields =
      Enum.map(fields, fn {_, value} ->
        Enum.reduce(value, %{}, fn {_, %{"key" => key, "value" => value}}, acc ->
          Map.put(acc, key, value)
        end)
      end)

    changeset(module, %{params | "fields" => new_fields})
  end

  def changeset(module, params) do
    module
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def test() do
    params =
      %{
        "_persistent_id" => "0",
        "base_selector" => "[data-component-type='s-search-result']",
        "fields" => %{
          "0" => %{
            "0" => %{"key" => "name", "value" => "asin"},
            "1" => %{"key" => "selector", "value" => ""},
            "2" => %{"key" => "type", "value" => "attribute"},
            "3" => %{"key" => "attribute", "value" => "data-asin"}
          },
          "1" => %{
            "0" => %{"key" => "name", "value" => "title"},
            "1" => %{"key" => "selector", "value" => "h2 a span"},
            "2" => %{"key" => "type", "value" => "text"}
          }
        },
        "name" => "Amazon Product Search Results"
      }

    fields = params["fields"]

    new_fields =
      Enum.map(fields, fn {_, value} ->
        Enum.reduce(value, %{}, fn {_, %{"key" => key, "value" => value}}, acc ->
          Map.put(acc, key, value)
        end)
      end)

    %{params | "fields" => new_fields}
  end
end
