defmodule SpiderPig.Crawler do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias SpiderPig.{
    Crawler,
    Repo
  }

  @type t :: %__MODULE__{}

  @status [:enable, :disable]

  schema "crawlers" do
    field :name, :string
    field :url, :string
    field :cron, :string
    field :status, Ecto.Enum, values: @status

    has_one :browser_config, Crawler.BrowserConfig
    has_many :nodes, Crawler.Node

    timestamps(type: :utc_datetime)
  end

  @optional_fields []
  @required_fields [:name, :url, :cron, :status]

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:nodes)
  end

  @spec list_crawlers() :: list(Crawler.t())
  def list_crawlers() do
    __MODULE__
    |> order_by(asc: :id)
    |> Repo.all()
  end

  @spec get_all_status() :: list(atom())
  def get_all_status(), do: @status

  @spec get_crawler!(integer()) :: Crawler.t()
  def get_crawler!(id) do
    get_query(id) |> Repo.one!()
  end

  @spec get_crawler(integer()) :: Crawler.t() | nil
  def get_crawler(id) do
    get_query(id) |> Repo.one()
  end

  @spec delete_crawler(t()) :: {:ok, t()}
  def delete_crawler(%__MODULE__{} = crawler) do
    Repo.delete(crawler)
  end

  def change_crawler(%__MODULE__{} = crawler, params \\ %{}) do
    changeset(crawler, params)
  end

  defp get_query(id) do
    from(
      c in __MODULE__,
      where: c.id == ^id,
      preload: [nodes: [extraction_strategy: [:schema]]]
    )
  end

  @spec to_standard_format(Crawler.t(), Crawler.Node.t()) :: map()
  def to_standard_format(%__MODULE__{} = crawler, %Crawler.Node{} = current_node) do
    map = %{
      "urls" => [crawler.url],
      "crawler_config" => Crawler.Node.to_standard_format(current_node)
    }

    case crawler do
      %{browser_config: browser_config} when is_struct(browser_config, Crawler.BrowserConfig) ->
        value = Crawler.BrowserConfig.to_standard_format(browser_config)
        Map.put(map, "browser_config", value)

      _ ->
        map
    end
  end
end
