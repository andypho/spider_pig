defmodule SpiderPig.Crawler.ExtractionStrategy.FieldsType do
  @moduledoc """
  Custom Ecto type for handling extraction strategy fields.

  When loading from the database, converts maps to lists of tuples.
  When saving to the database, converts lists of tuples to maps.
  """
  use Ecto.Type

  def type, do: {:array, :map}

  # Cast when data comes from forms
  def cast(fields) when is_list(fields), do: {:ok, fields}
  def cast(_), do: :error

  # Load from database (convert maps to lists of tuples)
  def load(fields) when is_list(fields) do
    result =
      Enum.map(fields, fn field_map ->
        Enum.map(field_map, fn
          {key, value} ->
            {key, value}
        end)
      end)

    {:ok, result}
  end

  def load(nil), do: {:ok, []}
  def load(_), do: :error

  # Dump to database (convert lists of tuples to maps)
  def dump(fields) when is_list(fields) do
    result =
      Enum.map(fields, fn field_tuples ->
        Enum.reduce(field_tuples, %{}, fn
          {key, value}, acc when is_atom(key) -> Map.put(acc, Atom.to_string(key), value)
          {key, value}, acc -> Map.put(acc, key, value)
        end)
      end)

    {:ok, result}
  end

  def dump(nil), do: {:ok, []}
  def dump(_), do: :error

  def dump!(fields) when is_list(fields) do
    case dump(fields) do
      {:ok, result} -> result
      _ -> raise "Failed to dump fields"
    end
  end

  def dump!(nil), do: []
  def dump!(_), do: raise("Failed to dump fields")
end
