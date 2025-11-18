defmodule SpiderPigWeb.Helper do
  def to_options(list) do
    Enum.map(list, fn
      {_, value} ->
        {value, value}

      status when is_atom(status) ->
        status = Atom.to_string(status)
        {String.capitalize(status), status}

      status ->
        {String.capitalize(status), status}
    end)
  end
end
