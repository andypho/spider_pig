defmodule SpiderPig.Repo do
  use Ecto.Repo,
    otp_app: :spider_pig,
    adapter: Ecto.Adapters.Postgres
end
