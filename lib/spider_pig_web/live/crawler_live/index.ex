defmodule SpiderPigWeb.CrawlerLive.Index do
  use SpiderPigWeb, :live_view

  alias SpiderPig.{
    Crawler
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:actions>
          <.button variant="primary" navigate={~p"/crawlers/new"}>
            <.icon name="hero-plus" /> New Crawler
          </.button>
        </:actions>
      </.header>

      <.table
        id="crawlers"
        rows={@streams.crawlers}
        row_click={fn {_id, crawler} -> JS.navigate(~p"/crawlers/#{crawler}") end}
      >
        <:col :let={{_id, crawler}} label="ID">{crawler.id}</:col>
        <:col :let={{_id, crawler}} label="Name">{crawler.name}</:col>
        <:col :let={{_id, crawler}} label="Url">{crawler.url}</:col>
        <:col :let={{_id, crawler}} class="whitespace-nowrap" label="Status">
          <.status type={if crawler.status == :enable, do: "success", else: "error"} />
          {to_string(crawler.status) |> String.capitalize()}
        </:col>
        <:action :let={{_id, crawler}}>
          <div class="sr-only">
            <.link navigate={~p"/crawlers/#{crawler}"}>Show</.link>
          </div>
          <.link navigate={~p"/crawlers/#{crawler}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, crawler}}>
          <.link
            phx-click={JS.push("delete", value: %{id: crawler.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Crawlers")
     |> stream(:crawlers, Crawler.list_crawlers())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    crawler = Crawler.get_crawler!(id)
    Crawler.delete_crawler(crawler)

    {:noreply, stream_delete(socket, :crawlers, crawler)}
  end
end
