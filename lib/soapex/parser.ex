defmodule Soapex.Parser do
  @moduledoc """
  Parses JSON request body.
  JSON documents that aren't maps (arrays, strings, numbers, etc) are parsed
  into a `"_json"` key to allow proper param merging.
  An empty request body is parsed as an empty map.
  ## Options
  All options supported by `Plug.Conn.read_body/2` are also supported here.
  They are repeated here for convenience:
    * `:length` - sets the maximum number of bytes to read from the request,
      defaults to 8_000_000 bytes
    * `:read_length` - sets the amount of bytes to read at one time from the
      underlying socket to fill the chunk, defaults to 1_000_000 bytes
    * `:read_timeout` - sets the timeout for each socket read, defaults to
      15_000ms
  So by default, `Plug.Parsers` will read 1_000_000 bytes at a time from the
  socket with an overall limit of 8_000_000 bytes.
  """

  @behaviour Plug.Parsers

  @impl true
  def init(opts) do
    Keyword.pop(opts, :body_reader, {Plug.Conn, :read_body, []})
  end

  @impl true
  def parse(conn, _, subtype, _headers, {{mod, fun, args}, opts}) do
    if subtype == "xml" or String.ends_with?(subtype, "+xml") do
      apply(mod, fun, [conn, opts | args]) |> handle_body()
    else
      {:next, conn}
    end
  end

  # We do not return the body as params, because that would be
  # printed every time the parser is called and logging is active
  defp handle_body({:ok, _, conn}) do
    {:ok, %{}, conn}
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
