defmodule Soapex.SoapController do

  defmacro __using__(opts) do

    quote bind_quoted: [opts: opts] do

      require Record

      plug Soapex.Plugs.Soap, opts

      model = Erlsom.Records.get_model(opts)
      @model model

      # grab record names from model
      records = model |> Erlsom.Model.extract_records

      for {tag, record_def} <- records do
        fun_name = tag |> Erlsom.Records.xml_name_to_atom

        record_def = record_def
          |> Erlsom.Records.record_def_underscore

        Record.defrecordp fun_name, tag, record_def

        defp to_kwlist(unquote(tag), record), do: unquote(fun_name)(record)
      end

      def to_struct({{key, 'http://www.w3.org/2001/XMLSchema-instance'}, value}) do
        key = "xsi_#{to_string(key)}"
        %{key => to_struct(value)}
      end

      def to_struct(record) when record |> is_tuple do
        tag = elem(record, 0)
        to_kwlist(tag, record)
        |> Enum.map(fn {key, value} -> {key, to_struct(value)} end)
        |> Enum.into(%{})
      end
      def to_struct([]), do: []
      def to_struct([c|_] = chardata) when c |> is_integer, do: IO.chardata_to_string(chardata) # this will fail badly if the schema has integers in lists
      def to_struct([h|t]), do: [to_struct(h) | to_struct(t)]
      def to_struct(:undefined), do: nil
      def to_struct(other), do: other

      def action(conn, _) do
        case action_name(conn) do
          :service_call ->
            params = to_struct(conn.params)
            # TODO: check that conn.params is an erlsom record
            action_name = elem(conn.params, 0)
              |> Erlsom.Mapper.xml_name_to_action
            try do
              apply(__MODULE__, action_name, [conn, params])
            rescue
              e in Soapex.SoapFaultError ->
                soap conn, client_fault(e.message, e.detail)
              e in UndefinedFunctionError ->
                soap conn, client_fault("Undefined operation")
              e ->
                soap conn, client_fault(e.message)
            end

          action_name ->
            apply(__MODULE__, action_name, [conn, conn.params])
        end
      end

      defp xml(conn, content) do
        {:ok, xml} = content |> :erlsom.write(@model)

        conn
        |> put_resp_content_type("text/xml")
        |> send_resp(200, to_string(xml))
      end

      defp soap(conn, body_content) do
        xml conn, soap_Envelope(header: soap_Header(),
                                body: soap_Body("#any": [body_content]))
      end

      defp client_fault(faultstring, detail \\ nil) do
        detail = if detail do
          soap_detail("#any": [detail])
        else
          :undefined
        end
        soap_Fault(
          faultcode: {:qname, 'http://schemas.xmlsoap.org/soap/envelope/', 'Client', 'soap', ''},
          faultstring: to_charlist(faultstring),
          detail: detail)
      end
    end
  end
end
