defmodule SpiderPigWeb.CrawlerLive.Show do
  use SpiderPigWeb, :live_view

  alias SpiderPig.{
    Crawler
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Crawler {@crawler.id}
        <:subtitle>This is a crawler record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/crawlers"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/crawlers/#{@crawler}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit crawler
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@crawler.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Crawler")
     |> assign(:crawler, Crawler.get_crawler!(id))}
  end
end
