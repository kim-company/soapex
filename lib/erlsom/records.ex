defmodule Erlsom.Records do
  require Record

#  Record.defrecord :model,
#    Record.extract(:model, from_lib: "erlsom/include/../src/erlsom_parse.hrl")
##    Record.extract(:model, from_lib: "erlsom/../../../../deps/erlsom/src/erlsom_parse.hrl")
#  Record.defrecord :type,
#    Record.extract(:type, from_lib: "erlsom/include/../src/erlsom_parse.hrl")
##    Record.extract(:model, from_lib: "erlsom/../../../../deps/erlsom/src/erlsom_parse.hrl")
  Record.defrecord :wsdl,
    Record.extract(:wsdl, from_lib: "detergent/include/detergent.hrl")

  def xml_name_to_atom(name) do
    name
    |> to_string
    |> String.replace(":", "_")
    |> String.replace("/", "_")
    |> String.replace("-", "_")
    |> String.to_atom
  end

  def xml_remove_namespace(name) do
    case name |> to_string |> String.split(":", parts: 2) do
      [_, rest] -> rest
      _ -> name |> to_string
    end
  end

  def record_def_underscore(definition) do
    definition
    |> Enum.map(fn {key, default} ->
      {key |> to_string |> xml_remove_namespace |> Macro.underscore |> String.to_atom,
       if(default != :undefined_TODO, do: default)}
    end)
  end

  def get_model(opts) do
    opts = Enum.into(opts, %{})
    wsdl = Map.get(opts, :wsdl)
    config = Map.get(opts, :config)
    xsd_file = Map.get(opts, :xsd_file)
    wsdl_file = Map.get(opts, :wsdl_file)
    prefix = case Map.get(opts, :prefix) do
      nil -> :undefined
      string -> to_charlist(string)
    end

    cond do
      wsdl ->
        wsdl
        |> wsdl(:model)
      config ->
        :detergent.initModelFile(config)
        |> wsdl(:model)
      wsdl_file ->
        :detergent.initModel(to_charlist(wsdl_file), prefix)
        |> wsdl(:model)
      xsd_file ->
        {:ok, model} = :erlsom.compile_xsd_file(to_charlist(xsd_file), prefix: prefix)
        model
      true ->
        raise ArgumentError, "need wsdl_file or xsd_file option"
    end
  end


  defmacro __using__(opts) do

    quote bind_quoted: [opts: opts] do

      require Record

      model = Erlsom.Records.get_model(opts)
      @model model

      def erlsom_model, do: @model

      # grab record names from model
      records = model |> Erlsom.Model.extract_records

      for {tag, record_def} <- records do
        fun_name = tag |> Erlsom.Records.xml_name_to_atom

        record_def = record_def
          |> Erlsom.Records.record_def_underscore

        # IO.puts "defining #{fun_name} to #{tag} with #{inspect record_def}"
        Record.defrecordp fun_name, tag, record_def
      end

    end

  end
end
