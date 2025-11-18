defmodule SpiderPig.Crawler.BrowserConfig do
  @moduledoc """
  Schema and module for browser configuration settings.

  This module defines the structure for browser configuration including
  headless mode, HTTP headers, and additional browser arguments.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias SpiderPig.{
    Crawler,
    Repo
  }

  @type t :: %__MODULE__{}

  @default_headers %{
    "type" => "dict",
    "value" => %{
      "sec-ch-ua" =>
        "\"Chromium\";v=\"116\", \"Not_A Brand\";v=\"8\", \"Google Chrome\";v=\"116\""
    }
  }
  @default_extra_args ["--no-sandbox", "--disable-gpu"]

  schema "browser_configs" do
    belongs_to :crawler, Crawler

    field :headless, :boolean, default: true
    field :headers, :map, default: @default_headers
    field :extra_args, {:array, :string}, default: @default_extra_args

    timestamps(type: :utc_datetime)
  end

  @optional_fields [:headers, :extra_args]
  @required_fields [:headless]

  @doc false
  def changeset(module, params) do
    module
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_headers()
    |> validate_extra_args()
  end

  @doc """
  Creates a new browser configuration record.
  """
  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  @doc """
  Updates an existing browser configuration.
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(config, params) do
    config
    |> changeset(params)
    |> Repo.update()
  end

  @doc """
  Gets a browser configuration by ID.
  """
  @spec get(binary()) :: t() | nil
  def get(id), do: Repo.get(__MODULE__, id)

  @doc """
  Creates a browser configuration from the standard format.

  ## Examples

      iex> BrowserConfig.from_standard_format(%{
      ...>   "type" => "BrowserConfig",
      ...>   "params" => %{
      ...>     "headless" => true,
      ...>     "headers" => %{"type" => "dict", "value" => %{"sec-ch-ua" => "..."}},
      ...>     "extra_args" => ["--no-sandbox", "--disable-gpu"]
      ...>   }
      ...> })
  """
  @spec from_standard_format(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_standard_format(%{"type" => "BrowserConfig", "params" => params}) do
    headers =
      case params["headers"] do
        %{"type" => "dict", "value" => value} when is_map(value) -> value
        _ -> %{}
      end

    attrs = %{
      type: "BrowserConfig",
      headless: params["headless"] || true,
      headers: headers,
      extra_args: params["extra_args"] || []
    }

    create(attrs)
  end

  @doc """
  Converts to standard format for for Crawl4Ai
  """
  @spec to_standard_format(t()) :: map()
  def to_standard_format(%__MODULE__{} = config) do
    %{
      "type" => "BrowserConfig",
      "params" => %{
        "headless" => config.headless,
        "headers" => config.headers,
        "extra_args" => config.extra_args
      }
    }
  end

  # Private functions

  defp validate_headers(changeset) do
    case get_change(changeset, :headers) do
      nil -> changeset
      headers when is_map(headers) -> changeset
      _ -> add_error(changeset, :headers, "must be a map")
    end
  end

  defp validate_extra_args(changeset) do
    case get_change(changeset, :extra_args) do
      nil ->
        changeset

      args when is_list(args) ->
        if Enum.all?(args, &is_binary/1) do
          changeset
        else
          add_error(changeset, :extra_args, "must contain only strings")
        end

      _ ->
        add_error(changeset, :extra_args, "must be a list")
    end
  end
end
