defmodule SpiderPigWeb.PageController do
  use SpiderPigWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
