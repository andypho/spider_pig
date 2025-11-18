defmodule SpiderPig.Crawler.Edge do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler
  }

  schema "edges" do
    belongs_to :source, Crawler.Node
    belongs_to :target, Crawler.Node

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [])
    |> validate_required([])
  end
end
