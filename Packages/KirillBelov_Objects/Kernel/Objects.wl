(* ::Package:: *)

(* ::Chapter:: *)
(*Objects*)


(* ::Section::Closed:: *)
(*Begin package*)


BeginPackage["KirillBelov`Objects`"]; 


(* ::Section::Closed:: *)
(*Names*)


CreateType::usage = 
"CreateType[type, parent, init, {fields}] create type"; 


Object::usage = 
"Object[] base mutable object."; 


TypeQ::usage = 
"TypeQ[name] check that name is type"; 


ObjectQ::usage = 
"ObjectQ[expr] check that expr is mutable object"; 


(* ::Section::Closed:: *)
(*Private context*)


Begin["`Private`"]; 


(* ::Section:: *)
(*Object constructor*)


SetAttributes[Object, HoldFirst]; 


$objectDefaultIcon = 
Import[FileNameJoin[{DirectoryName[$InputFileName, 2], "Images", "ObjectIcon.png"}]]; 


Options[Object] = {
    "Icon" :> $objectDefaultIcon, 
    "Init" -> Identity, 
    "PublicFields" -> {"Properties"}
}; 


Object[opts: OptionsPattern[]] := 
With[{symbol = Unique[Context[Object] <> SymbolName[Object] <> "`$"], 
    fullOpts = Normal[Join[<|Options[Object]|>, <|Flatten[{opts}]|>]]}, 
    symbol = <||>; 
    Table[opt /. {
        _[k_String, v_] :> SetDelayed[symbol[k], v], 
        _[k_Symbol, v_] :> With[{ks = SymbolName[k]}, SetDelayed[symbol[ks], v]]
    }, {opt, fullOpts}]; 
    symbol["Self"] := symbol; 
    symbol["Properties"] := Keys[symbol]; 
    symbol["Init"] @ Object[symbol]; 
    Return[Object[symbol]]
]; 


Object[assoc_Association] := 
If[KeyExistsQ[assoc, "Self"], 
    Object["Self"] /. assoc, 
(*Else*)
    With[{symbol = Unique[Context[Object] <> SymbolName[Object] <> "`$"]}, 
        symbol = assoc; 
        symbol["Self"] := symbol; 
        symbol["Properties"] := Keys[symbol]; 
        If[KeyExistsQ[symbol, "Init"], symbol["Init"] @ Object[symbol]]; 
        Object[symbol]
    ]
]; 


Object[assoc: Except[_Symbol | _Association] ? AssociationQ] := 
With[{a = assoc}, Object[a]]; 


(* ::Section::Closed:: *)
(*DeleteObject*)


Object /: DeleteObject[Object[symbol_Symbol]] := 
Remove[symbol]; 


(* ::Section::Closed:: *)
(* Normal*)


Object /: Normal[Object[symbol_Symbol]] := 
symbol; 


(* ::Section::Closed:: *)
(*TypeQ Object*)


Object /: TypeQ[Object] = 
True; 


(* ::Section::Closed:: *)
(*ObjectQ Object*)


ObjectQ[___] := 
False; 


Object /: ObjectQ[Object[symbol_Symbol]] = 
True; 


(* ::Section::Closed:: *)
(*Get*)


Object[symbol_Symbol][key_String] := 
symbol[key]; 


Object[symbol_Symbol][key_Symbol] := 
symbol[SymbolName[key]]; 


Object[symbol_Symbol][key_String, keys__] := 
symbol[key][keys]; 


Object[symbol_Symbol][key_Symbol, keys__] := 
symbol[SymbolName[key]][keys]; 


(* ::Section:: *)
(*Set*)


Object /: Set[Object[symbol_Symbol][key_String], value_] := 
symbol[key] = value; 


Object /: SetDelayed[Object[symbol_Symbol][key_String], value_] := 
symbol[key] := value; 


Object /: Set[Object[symbol_Symbol][key_Symbol], value_] := 
With[{k = SymbolName[key]}, symbol[k] = value]; 


Object /: SetDelayed[Object[symbol_Symbol][key_Symbol], value_] := 
With[{k = SymbolName[key]}, symbol[k] := value]; 


Object /: Set[Object[symbol_Symbol][keys__, key_], value_] := 
With[{part = Object[symbol][keys]}, 
    Which[
        AssociationQ[part], 
            Object[symbol][keys] = Append[part, key -> value], 
        True, 
            part[key] = value
    ]; 
    value
]; 


Object /: SetDelayed[Object[symbol_Symbol][keys__, key_], value_] := 
With[{part = Object[symbol][keys]}, 
    Which[
        AssociationQ[part], 
            Object[symbol][keys] = Append[part, key :> value], 
        True, 
            part[key] := value
    ]; 
]; 


Object /: Set[Object[symbol_Symbol][keys__, key_Symbol], value_] := 
With[{k = SymbolName[key]}, Object[symbol][keys, k] = value]; 


Object /: SetDelayed[Object[symbol_Symbol][keys__, key_Symbol], value_] := 
With[{k = SymbolName[key]}, Object[symbol][keys, k] := value]; 


Object /: Set[name_Symbol, object_Object] := (
    ClearAll[name]; 
    Block[{Object}, SetAttributes[Object, HoldFirst]; name = object]; 
    name /: Set[name[keys__], value_] := object[keys] = value; 
    name /: SetDelayed[name[keys__], value_] := object[keys] := value; 
    name /: Unset[name[key_String]] := Unset[object[key]]; 
    name
); 


(* ::Section:: *)
(*UnSet*)


Object /: Unset[Object[symbol_Symbol][key_String]] := 
Unset[symbol[key]]; 


(* ::Section::Closed:: *)
(*Summary Box*)


Object /: MakeBoxes[object: Object[symbol_Symbol?AssociationQ], form: (StandardForm | TraditionalForm)] := 
Module[{above, below}, 
    above = Join[
        {{BoxForm`SummaryItem[{"Self: ", Defer["Self"] /. symbol}], SpanFromLeft}}, 
        Map[{BoxForm`SummaryItem[{# <> ": ", symbol[#]}], SpanFromLeft}&] @ symbol["PublicFields"]
    ]; 

    below = {}; 
    
    (*Return*)
    BoxForm`ArrangeSummaryBox[Head[object], object, symbol["Icon"], above, below, form, "Interpretable" -> Automatic]
];


(* ::Section::Closed:: *)
(*TypeQ*)


TypeQ[___] := 
False; 


(* ::Section:: *)
(*Create type*)


CreateType[type_Symbol, parent_Symbol?TypeQ, init: _Symbol | _Function, fields_Association] := 
Module[{
    messages = Messages[type], 
    upValues = UpValues[type],
    subValues = SubValues[type], 
    downValues = DownValues[type]
}, 
    ClearAll[type]; 
    type /: TypeQ[type] = True; 
    Language`ExtendedFullDefinition[type] = Language`ExtendedFullDefinition[parent] /. parent -> type; 
    Messages[type] = Normal[<|Messages[type], messages|>];
    UpValues[type] = Normal[<|UpValues[type], upValues|>];
    SubValues[type] = Normal[<|SubValues[type], subValues|>];
    DownValues[type] = Normal[<|DownValues[type], downValues|>];
    Options[type] = Normal[<|Join[Options[type], Normal[fields], {If[init === Automatic, Nothing, "Init" -> init]}]|>]; 
    type
]; 


CreateType[type_Symbol, parent: _Symbol?TypeQ: Object, init: _Symbol | _Function: Automatic, fields_List: {}] := 
Module[{assoc = Association[Map[
    Switch[#, 
        _String -> _, #, 
        _String, # -> Automatic, 
        _Symbol -> _, SymbolName[#[[1]]] -> #[[2]], 
        _Symbol, SymbolName[#] -> Automatic, 
        _Symbol :> _, # /. r_[k_, v] :> r[SymbolName[k], v], 
        _String :> _, #
    ]&
] @ fields]}, 
    CreateType[type, parent, init, assoc]
]; 


(* ::Section::Closed:: *)
(*End private context*)


End[]; (*`Private`*)


(* ::Section::Closed:: *)
(*End package*)


EndPackage[]; (*KirillBelov`Objects`*)
