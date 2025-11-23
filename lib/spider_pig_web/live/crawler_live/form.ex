defmodule SpiderPigWeb.CrawlerLive.Form do
  use SpiderPigWeb, :live_view

  alias SpiderPigWeb.Helper

  alias SpiderPig.{
    Crawler,
    Repo
  }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage crawler records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="crawler-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:cron]} type="text" label="Cron" />

        <.button_group label="Browser Configuration" options={["Default", "Custom", "Off"]} />

        <div class="fieldset">
          <span class="label mb-1">Nodes</span>
        </div>

        <.inputs_for :let={node} field={@form[:nodes]}>
          <.input :if={not is_nil(node[:id][:value])} field={node[:id]} type="text" hidden />

          <div class="flex items-end gap-4">
            <div class="flex-1">
              <.input field={node[:name]} type="text" label="Name" />
            </div>

            <div class="fieldset mb-2">
              <.tooltip title="Delete Node" type="button" phx-click="delete_node">
                <.icon name="hero-minus-circle" class="size-5" />
              </.tooltip>
            </div>
          </div>

          <div class="fieldset">
            <span class="label mb-1">Extraction Strategy</span>
          </div>

          <.inputs_for :let={extraction_strategy} field={node[:extraction_strategy]}>
            <.input
              field={extraction_strategy[:type]}
              type="select"
              label="Type"
              options={Crawler.ExtractionStrategy.get_all_type() |> Helper.to_options()}
            />

            <.inputs_for :let={schema} field={extraction_strategy[:schema]}>
              <.input field={schema[:name]} type="text" label="Name" />
              <.input field={schema[:base_selector]} type="text" label="Base Selector" />

              <div class="fieldset">
                <div class="w-full flex justify-between">
                  <span class="label mb-1">Fields</span>

                  <.button onclick="fast_edit_modal.showModal()">
                    Fast Edit
                  </.button>
                </div>
              </div>

              <%= for {key_value_pair, field_index} <- Enum.with_index(schema[:fields][:value]) do %>
                <.card class="p-4">
                  <%= Enum.with_index(key_value_pair, fn {key, value}, index -> %>
                    <div class="flex items-end gap-4">
                      <div class="flex-1">
                        <.input
                          name={schema[:fields][:name] <> "[#{field_index}][#{index}][key]"}
                          value={key}
                          type="text"
                          label="Key"
                        />
                      </div>
                      <div class="flex-1">
                        <.input
                          name={schema[:fields][:name] <> "[#{field_index}][#{index}][value]"}
                          value={value}
                          type="text"
                          label="Value"
                        />
                      </div>

                      <div class="fieldset mb-2">
                        <.tooltip
                          title="Delete Key-Value Pair"
                          type="button"
                          phx-click="delete_key_value_pair"
                          phx-value-node_index={node.index}
                          phx-value-field_index={field_index}
                          phx-value-index={index}
                        >
                          <.icon name="hero-minus-circle" class="size-5" />
                        </.tooltip>
                      </div>
                    </div>
                  <% end) %>
                  <div class="flex justify-end">
                    <.button
                      variant="primary"
                      type="button"
                      phx-click="add_key_value_pair"
                      phx-value-node_index={node.index}
                      phx-value-field_index={field_index}
                    >
                      <.icon name="hero-plus" class="size-5" /> Add Key-Value Pair
                    </.button>
                  </div>
                </.card>
              <% end %>
              <.button
                variant="primary"
                type="button"
                phx-click="add_field"
                phx-value-node_index={node.index}
              >
                <.icon name="hero-plus" class="size-5" /> Add Field
              </.button>
            </.inputs_for>
          </.inputs_for>
          <.divider />
        </.inputs_for>

        <div class="flex justify-end">
          <.button variant="primary" type="button" phx-click="add_node">
            <.icon name="hero-plus" class="size-5" /> Add Node
          </.button>
        </div>

        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={Crawler.get_all_status() |> Helper.to_options()}
        />

        <footer class="flex justify-end gap-4">
          <.button navigate={return_path(@return_to, @crawler)}>Cancel</.button>

          <.button phx-disable-with="Saving..." variant="primary" type="submit">
            Save Crawler
          </.button>
        </footer>
      </.form>

      <dialog id="fast_edit_modal" class="modal">
        <div class="modal-box">
          <form method="dialog">
            <.button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2" type="submit">
              ✕
            </.button>
          </form>
          <h3 class="text-lg font-bold">Fast Edit Toolbox</h3>
          <p class="py-4">
            You can use this toolbox to quickly edit the JSON data.
          </p>
          <textarea class="textarea h-24 w-full" placeholder="JSON"></textarea>
          <div class="modal-action">
            <form method="dialog">
              <.button type="submit" phx-click="fast_edit_update">Close</.button>
              <.button variant="primary" type="button">Update</.button>
            </form>
          </div>
        </div>
      </dialog>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("add_node", _params, socket) do
    crawler = Ecto.Changeset.apply_changes(socket.assigns.crawler)

    nodes =
      crawler.nodes ++
        [
          %Crawler.Node{
            extraction_strategy: %Crawler.ExtractionStrategy{
              schema: %Crawler.ExtractionStrategy.Schema{}
            }
          }
        ]

    crawler =
      Crawler.change_crawler(crawler)
      |> Ecto.Changeset.put_assoc(:nodes, nodes)

    {:noreply,
     socket
     |> assign(:crawler, crawler)
     |> assign(:form, to_form(crawler))}
  end

  # TODO
  def handle_event("delete_node", _params, socket) do
    {:noreply, socket}
  end

  # TODO
  def handle_event("fast_edit_update", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("add_field", %{"node_index" => node_index}, socket) do
    node_index = String.to_integer(node_index)

    crawler = Ecto.Changeset.apply_changes(socket.assigns.crawler)

    new_nodes =
      List.update_at(crawler.nodes, node_index, fn node ->
        case node do
          %{extraction_strategy: %{schema: %{fields: fields}}} ->
            updated_fields = fields ++ [[{"", ""}]]

            %{
              node
              | extraction_strategy: %{
                  node.extraction_strategy
                  | schema: %{node.extraction_strategy.schema | fields: updated_fields}
                }
            }

          _ ->
            node
        end
      end)

    crawler =
      Crawler.change_crawler(%{crawler | nodes: new_nodes})
      |> Ecto.Changeset.cast_assoc(:nodes)

    {:noreply,
     socket
     |> assign(:crawler, crawler)
     |> assign(:form, to_form(crawler))}
  end

  def handle_event(
        "add_key_value_pair",
        %{"node_index" => node_index, "field_index" => field_index},
        socket
      ) do
    node_index = String.to_integer(node_index)
    field_index = String.to_integer(field_index)

    crawler = Ecto.Changeset.apply_changes(socket.assigns.crawler)

    new_nodes =
      List.update_at(crawler.nodes, node_index, fn node ->
        case node do
          %{extraction_strategy: %{schema: %{fields: fields}}} ->
            updated_fields =
              List.update_at(fields, field_index, fn sublist ->
                sublist ++ [{"", ""}]
              end)

            %{
              node
              | extraction_strategy: %{
                  node.extraction_strategy
                  | schema: %{node.extraction_strategy.schema | fields: updated_fields}
                }
            }

          _ ->
            node
        end
      end)

    crawler =
      Crawler.change_crawler(%{crawler | nodes: new_nodes})
      |> Ecto.Changeset.cast_assoc(:nodes)

    {:noreply,
     socket
     |> assign(:crawler, crawler)
     |> assign(:form, to_form(crawler))}
  end

  def handle_event(
        "delete_key_value_pair",
        %{"node_index" => node_index, "field_index" => field_index, "index" => index},
        socket
      ) do
    node_index = String.to_integer(node_index)
    field_index = String.to_integer(field_index)
    index = String.to_integer(index)

    crawler = Ecto.Changeset.apply_changes(socket.assigns.crawler)

    new_nodes =
      List.update_at(crawler.nodes, node_index, fn node ->
        case node do
          %{extraction_strategy: %{schema: %{fields: fields}}} ->
            updated_fields =
              List.update_at(fields, field_index, fn sublist ->
                List.delete_at(sublist, index)
              end)

            %{
              node
              | extraction_strategy: %{
                  node.extraction_strategy
                  | schema: %{node.extraction_strategy.schema | fields: updated_fields}
                }
            }

          _ ->
            node
        end
      end)

    crawler =
      Crawler.change_crawler(%{crawler | nodes: new_nodes})
      |> Ecto.Changeset.cast_assoc(:nodes)

    {:noreply,
     socket
     |> assign(:crawler, crawler)
     |> assign(:form, to_form(crawler))}
  end

  # FIXME
  def handle_event("validate", %{"crawler" => crawler_params}, socket) do
    changeset = Crawler.change_crawler(socket.assigns.crawler, crawler_params)
    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  # TODO
  def handle_event("save", %{"crawler" => crawler_params}, socket) do
    case socket.assigns.crawler do
      %Ecto.Changeset{data: %Crawler{id: nil}} ->
        Crawler.changeset(%Crawler{}, crawler_params)
        |> Repo.insert()

      %Ecto.Changeset{data: c} ->
        Crawler.changeset(c, crawler_params)
        |> Repo.update()

      _ ->
        {:error, "Unexpected error"}
    end
    |> case do
      {:ok, crawler} ->
        {:noreply,
         socket
         |> put_flash(:info, "Crawler created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, crawler))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create crawler")}
    end
  end

  defp return_path("index", _), do: ~p"/crawlers"
  defp return_path("show", %Ecto.Changeset{data: %{id: id}}), do: ~p"/crawlers/#{id}"
  defp return_path("show", %Crawler{id: id}), do: ~p"/crawlers/#{id}"

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    crawler =
      Crawler.get_crawler!(id)
      |> Crawler.change_crawler()

    socket
    |> assign(:page_title, "Edit Crawler")
    |> assign(:crawler, crawler)
    |> assign(:form, to_form(crawler))
  end

  defp apply_action(socket, :new, _params) do
    nodes = [
      %Crawler.Node{
        name: "Step 1",
        extraction_strategy: %Crawler.ExtractionStrategy{
          schema: %Crawler.ExtractionStrategy.Schema{}
        }
      }
    ]

    crawler = Ecto.Changeset.change(%Crawler{nodes: nodes})

    socket
    |> assign(:page_title, "New Crawler")
    |> assign(:crawler, crawler)
    |> assign(:form, to_form(crawler))
  end

  # TODO remove
  def test_data() do
    nodes = [
      %Crawler.Node{
        name: "Start",
        extraction_strategy: %Crawler.ExtractionStrategy{
          node: nil,
          schema: %Crawler.ExtractionStrategy.Schema{
            name: "Amazon Product Search Results",
            base_selector: "[data-component-type='s-search-result']",
            fields: [
              [
                {"name", "asin"},
                {"selector", ""},
                {"type", "attribute"},
                {"attribute", "data-asin"}
              ],
              [
                {"name", "title"},
                {"selector", "h2 a span"},
                {"type", "text"}
              ],
              [
                {"name", "url"},
                {"selector", "h2 a"},
                {"type", "attribute"},
                {"attribute", "href"}
              ],
              [
                {"name", "image"},
                {"selector", ".s-image"},
                {"type", "attribute"},
                {"attribute", "src"}
              ],
              [
                {"name", "rating"},
                {"selector", ".a-icon-star-small .a-icon-alt"},
                {"type", "text"}
              ],
              [
                {"name", "reviews_count"},
                {"selector", "[data-csa-c-func-deps='aui-da-a-popover'] ~ span span"},
                {"type", "text"}
              ],
              [
                {"name", "price"},
                {"selector", ".a-price .a-offscreen"},
                {"type", "text"}
              ],
              [
                {"name", "original_price"},
                {"selector", ".a-price.a-text-price .a-offscreen"},
                {"type", "text"}
              ],
              [
                {"name", "sponsored"},
                {"selector", ".puis-sponsored-label-text"},
                {"type", "exists"}
              ],
              [
                {"name", "delivery_info"},
                {"selector", "[data-cy='delivery-recipe'] .a-color-base"},
                {"type", "text"},
                {"multiple", "true"}
              ],
              [
                {"name", "next_page"},
                {"selector", ".s-pagination-next"},
                {"type", "attribute"},
                {"attribute", "href"}
              ]
            ]
          }
        }
      }
    ]

    %Crawler{
      name: "Amazon",
      url: "https://www.amazon.com.au/s?k=Samsung+Galaxy+Tab",
      cron: "0 * * * *",
      status: "enable",
      nodes: nodes
    }
    |> Ecto.Changeset.change()
  end
end
