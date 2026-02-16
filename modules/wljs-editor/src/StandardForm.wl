System`RowBoxFlatten;
RowBoxFlatten[x_List, y___] := StringJoin @@ (ToString[#] & /@ x)

System`ProvidedOptions;

Begin["CoffeeLiqueur`Extensions`StandardForm`"]

Unprotect[TraditionalForm]
TraditionalForm::nspt = "TraditionalForm is not supported in WLJS. ToString is applied"
TraditionalForm[expr_] := (Message[TraditionalForm::nspt]; ToString[expr])

System`ByteArrayWrapper;
System`TreeWrapper;

(* Overrride FormatValues*)
(* FIXME *)
ExpressionReplacements = {
    t_Tree :> TreeWrapper[t],
    TreeForm[expr_] :> (ExpressionTree[Unevaluated[expr] ] /. t_Tree :> TreeWrapper[t])
} // Quiet

Unprotect[ToString]
ToString[expr_, StandardForm] := ExportString[
    StringReplace[
        (expr /. ExpressionReplacements // ToBoxes) /. {RowBox->RowBoxFlatten} // ToString
    , {"\[NoBreak]"->""}]
, "String"]


End[]
