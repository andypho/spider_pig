defmodule SpiderPig.CrawlerWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    # TODO
    :ok
  end
end
