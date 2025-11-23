defmodule SpiderPig.CrawlerWorker do
  use Oban.Worker, queue: :default

  require Logger

  alias SpiderPig.{
    Crawler
  }

  # TODO
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Crawler.get_crawler(id)

    :ok
  end

  def perform(job) do
    Logger.error("CrawlerWorker: Unknown job: #{inspect(job)}")
    :ok
  end
end
