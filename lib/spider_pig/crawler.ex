defmodule SpiderPig.Crawler do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler
  }

  schema "crawlers" do
    field :name, :string
    field :url, :string

    has_many :nodes, Crawler.Node

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
