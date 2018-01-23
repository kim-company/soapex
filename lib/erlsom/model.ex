defmodule Erlsom.Model do

#from_model = Erlsom.Model.extract_records(model, tag)
#from_hrl = Record.Extractor.extract(tag, from: hrl)
#^from_model = from_hrl

#  Record.defrecord :model,
#    Record.extract(:model, from_lib: "erlsom/include/../src/erlsom_parse.hrl")
##    Record.extract(:model, from_lib: "erlsom/../../../../deps/erlsom/src/erlsom_parse.hrl")
#  Record.defrecord :type,
#    Record.extract(:type, from_lib: "erlsom/include/../src/erlsom_parse.hrl")
##    Record.extract(:model, from_lib: "erlsom/../../../../deps/erlsom/src/erlsom_parse.hrl")

  def extract_records(erlsom_model) do
    erlsom_model
#    |> model(:tps)
    |> elem(1)
#    |> Enum.map(&type(&1, :nm))
    |> Enum.filter(&(elem(&1, 1) != :_document))
    |> Enum.map(&{elem(&1, 1), to_record(&1)})
  end

  # {:type, :"tns:ProjectType", :sequence, [els], [atts], :undefined, :undefined, 9, 1, 1, :undefined, :undefined}
  defp to_record({:type, _nm, _tp=:sequence, els, atts, _anyAttr, _nillable, _nr, _mn, _mx, _mxd, _typeName}) do
    [anyAttribs: :undefined] ++
    Enum.map(atts, &to_record/1) ++
    Enum.map(els, &to_record/1)
  end

  # {:el, [alts], 1, 1, :undefined, 2},
  defp to_record({:el, [alt], _mn, _mx, _nillable, _nr}) do
    to_record(alt)
  end
  defp to_record({:el, [_|_] = _alts, _mn, _mx, _nillable, _nr}) do
    {:choice, :undefined}
  end

  # [{:alt, :"tns:projectCode", {:"#PCDATA", :char}, [], 1, 1, true, :undefined}],
  defp to_record({:alt, tag, _tp, _nxt, _mn, _mx, _rl, _anyInfo}) do
    {tag, :undefined}
  end

  # {:att, :projectID, 1, true, :char}
  defp to_record({:att, nm, _nr, _opt, _tp}) do
    {nm, :undefined}
  end
end
