defmodule SpiderPig.Crawl4Ai do
  @moduledoc """
  This module provides functions for interacting with the Crawl4AI API.

  The API is configured through the `:spider_pig` application environment.
  The configuration values are:

    * `:scheme` - the scheme of the API
    * `:host` - the host of the API
    * `:port` - the port of the API

  The functions provided by this module are:

    * `get_url/0` - returns the base URL of the API
    * `get_request_headers/0` - returns the list of headers to include in every request

  """
  @config Application.compile_env(:spider_pig, __MODULE__)
  @url Map.merge(%URI{}, Map.new(@config)) |> URI.to_string()

  @spec get_url() :: String.t()
  def get_url(), do: @url

  @spec get_request_headers() :: list({String.t(), String.t()})
  def get_request_headers() do
    %{"content-type" => ["application/json"]}
  end

  @spec get() :: {:ok, Req.Response.t()} | {:error, Exception.t()}
  def get(), do: Req.get(@url)

  @spec get!() :: Req.Response.t()
  def get!(), do: Req.get!(@url)

  @spec post(body :: map(), headers :: list()) ::
          {:ok, Req.Response.t()} | {:error, Exception.t()}
  def post(body, headers \\ get_request_headers()) when is_map(body) do
    body = Jason.encode!(body)
    Req.post(@url, body: body, headers: headers)
  end

  @spec post!(body :: map(), headers :: list()) :: Req.Response.t()
  def post!(body, headers \\ get_request_headers()) when is_map(body) do
    body = Jason.encode!(body)
    Req.post!(@url, body: body, headers: headers)
  end

  @spec crawl(body :: map(), headers :: list()) :: Req.Response.t()
  def crawl(body, headers \\ get_request_headers()) when is_map(body) do
    body = Jason.encode!(body)
    Req.post(@url <> "/crawl", body: body, headers: headers)
  end

  @spec crawl!(body :: map(), headers :: list()) :: Req.Response.t()
  def crawl!(body, headers \\ get_request_headers()) when is_map(body) do
    body = Jason.encode!(body)
    Req.post!(@url <> "/crawl", body: body, headers: headers)
  end

  @spec get_extracted_content(map) :: {:ok, list()} | {:error, String.t()}
  def get_extracted_content(%{"results" => [%{"extracted_content" => ec} | _]}) do
    case Jason.decode(ec) do
      {:ok, term} -> {:ok, term}
      _ -> {:error, "Failed to decode extracted content"}
    end
  end

  def get_extracted_content(_), do: {:error, "Failed to get extracted content"}
end
