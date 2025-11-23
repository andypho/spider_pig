defmodule SpiderPig.Crawler do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias SpiderPig.{
    Crawler,
    CrawlerWorker,
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

  @spec to_standard_format(Crawler.t(), Crawler.Node.t() | nil) ::
          {:ok, map()} | {:error, String.t()}
  def to_standard_format(crawler, current_node \\ nil)

  def to_standard_format(%__MODULE__{} = crawler, nil) do
    crawler = Repo.preload(crawler, :nodes)

    List.first(crawler.nodes)
    |> case do
      nil -> {:error, "No node found"}
      current_node -> to_standard_format(crawler, current_node)
    end
  end

  def to_standard_format(%__MODULE__{} = crawler, %Crawler.Node{} = current_node) do
    map = %{
      "urls" => [crawler.url],
      "crawler_config" => Crawler.Node.to_standard_format(current_node)
    }

    map =
      case crawler do
        %{browser_config: browser_config} when is_struct(browser_config, Crawler.BrowserConfig) ->
          value = Crawler.BrowserConfig.to_standard_format(browser_config)
          Map.put(map, "browser_config", value)

        _ ->
          map
      end

    {:ok, map}
  end

  @spec to_standard_format!(Crawler.t(), Crawler.Node.t() | nil) :: map()
  def to_standard_format!(crawler, node \\ nil) do
    to_standard_format(crawler, node)
    |> case do
      {:ok, map} -> map
      {:error, error} -> raise error
    end
  end

  def schedule_job(%__MODULE__{id: id, cron: cron}) do
    scheduled_at = CronParser.next_run_time(cron)
    scheduled_at = DateTime.utc_now()

    %{id: id}
    |> CrawlerWorker.new(scheduled_at: scheduled_at)
    |> Oban.insert()
  end

  def test_schedule_job() do
    Crawler.get_crawler!(3)
    |> schedule_job()
  end

  def test_to_standard_format() do
    crawler = Crawler.get_crawler!(3)

    %{crawler | browser_config: %Crawler.BrowserConfig{}}
    |> to_standard_format()
  end

  def test_crawl() do
    {:ok, body} = test_to_standard_format()

    start_crawling(body)
    |> next_step()
  end

  def start_crawling(body) do
    SpiderPig.Crawl4Ai.crawl(body)
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:process_body, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "Failed to crawl. Status code: #{status}. Body: #{inspect(body)}"}

      error ->
        {:error, "Failed to crawl. Error: #{inspect(error)}"}
    end
  end

  def next_step({:process_body, body}) do
    SpiderPig.Crawl4Ai.get_extracted_content(body)
    |> case do
      {:ok, content} -> {:process_content, content}
      error -> error
    end
    |> next_step()
  end

  def next_step({:process_content, content}) do
    {:ok, content}
  end

  def next_step({:error, error}) do
    {:error, error}
  end

  def next_step(_) do
    {:finished, "Finished"}
  end

  def x() do
    %{
      "browser_config" => %{
        "params" => %{
          "extra_args" => ["--no-sandbox", "--disable-gpu"],
          "headers" => %{
            "type" => "dict",
            "value" => %{
              "sec-ch-ua" =>
                "\"Chromium\";v=\"116\", \"Not_A Brand\";v=\"8\", \"Google Chrome\";v=\"116\""
            }
          },
          "headless" => true
        },
        "type" => "BrowserConfig"
      },
      "crawler_config" => %{
        "params" => %{
          "extraction_strategy" => %{
            "params" => %{
              "schema" => %{
                "type" => "dict",
                "value" => %{
                  "baseSelector" => "[data-component-type='s-search-result']",
                  "fields" => [
                    %{
                      "attribute" => "data-asin",
                      "name" => "asin",
                      "selector" => "",
                      "type" => "attribute"
                    },
                    %{"name" => "title", "selector" => "h2 a span", "type" => "text"},
                    %{
                      "attribute" => "href",
                      "name" => "url",
                      "selector" => "h2 a",
                      "type" => "attribute"
                    },
                    %{
                      "attribute" => "src",
                      "name" => "image",
                      "selector" => ".s-image",
                      "type" => "attribute"
                    },
                    %{
                      "name" => "rating",
                      "selector" => ".a-icon-star-small .a-icon-alt",
                      "type" => "text"
                    },
                    %{
                      "name" => "reviews_count",
                      "selector" => "[data-csa-c-func-deps='aui-da-a-popover'] ~ span span",
                      "type" => "text"
                    },
                    %{"name" => "price", "selector" => ".a-price .a-offscreen", "type" => "text"},
                    %{
                      "name" => "original_price",
                      "selector" => ".a-price.a-text-price .a-offscreen",
                      "type" => "text"
                    },
                    %{
                      "name" => "sponsored",
                      "selector" => ".puis-sponsored-label-text",
                      "type" => "exists"
                    },
                    %{
                      "multiple" => true,
                      "name" => "delivery_info",
                      "selector" => "[data-cy='delivery-recipe'] .a-color-base",
                      "type" => "text"
                    },
                    %{
                      "attribute" => "href",
                      "name" => "next_page",
                      "selector" => ".s-pagination-next",
                      "type" => "attribute"
                    }
                  ],
                  "name" => "Amazon Product Search Results"
                }
              }
            },
            "type" => "JsonCssExtractionStrategy"
          }
        },
        "type" => "CrawlerRunConfig"
      },
      "urls" => ["https://www.amazon.com.au/s?k=Samsung+Galaxy+Tab"]
    }
    |> SpiderPig.Crawl4Ai.crawl()
  end
end
