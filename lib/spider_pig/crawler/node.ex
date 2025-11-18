defmodule SpiderPig.Crawler.Node do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler
  }

  schema "nodes" do
    field :name, :string
    belongs_to :crawler, Crawler

    has_many :edges, Crawler.Edge, foreign_key: :source_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
