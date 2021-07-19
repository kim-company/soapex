defmodule Soapex.Parser do
  @behaviour Plug.Parsers

  @impl true
  def init(opts) do
    Keyword.pop(opts, :body_reader, {Plug.Conn, :read_body, []})
  end

  @impl true
  def parse(conn, _, subtype, _headers, {{mod, fun, args}, opts}) do
    if subtype == "xml" or String.ends_with?(subtype, "+xml") do
      opts = Keyword.update!(opts, :length, &(ceil((&1 + 500) / 3) * 4))
      apply(mod, fun, [conn, opts | args]) |> handle_body()
    else
      {:next, conn}
    end
  end

  # We do not return the body as params, because that would be
  # printed every time the parser is called and logging is active
  defp handle_body({:ok, body, conn}) do
    {:ok, %{}, Plug.Conn.assign(conn, :raw_body, body)}
  end

  defp handle_body({:more, _, conn}) do
    {:error, :too_large, conn}
  end

  defp handle_body({:error, :timeout}) do
    raise Plug.TimeoutError
  end

  defp handle_body({:error, _}) do
    raise Plug.BadRequestError
  end
end
