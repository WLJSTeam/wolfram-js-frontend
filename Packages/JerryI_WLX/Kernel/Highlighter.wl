BeginPackage["JerryI`WLX`Highlighter`", {"JerryI`WLX`", "CodeParser`"}]

Highlight::usage = "Highlight WL expression"

HighlightTagStyle::usage = "Specify the styles function"

HighlightTagStyleSet::usage = "Helper to set the style"

Begin["`Private`"]

HighlightTagStyleSet[tag_String, func_] := HighlightTagStyle[tag] = func;

HighlightTagStyle[any_String] := Identity

Highlight[str_String] := Module[{open, close, singular, tokens, tree, placeholders, pureWLCode, map},

    {open, close, singular} = JerryI`WLX`Private`parseTags[str];
    
    (*parse all tokens*)

    tokens = 
      SortBy[
       Join[JerryI`WLX`Private`tokenizer[#, 1, str] & /@ open, 
        JerryI`WLX`Private`tokenizer[#, 0, str] & /@ singular, 
        JerryI`WLX`Private`tokenizer[#, -1, str] & /@ 
         close], #["pos"][[1]] &];

    If[Length[tokens] === 0,
        (* then it is just pure WL *)
        Return[StringSplit[StringRiffle[formAString /@ CodeParse[str][[2]], ""], "\n"], Module];
    ];


    JerryI`WLX`Private`fetchInnerText[tokens, str];
    tokens = 
      Join[tokens, JerryI`WLX`Private`fetchInnerText[tokens, str]];
    tokens = SortBy[tokens, #["pos"][[1]] &];

   

    (*build AST tree*)
    tree = JerryI`WLX`Private`ast[tokens, str];


    (*generate rules of string replacement*)
    

    placeholders = {JerryI`WLX`Private`generatePlaceholders[tree]} // Flatten;



    (*generate sanitized list of expressions*)

    pureWLCode = 
        With[{rules = Values[placeholders]}, 
         StringReplacePart[str, rules[[All, 1]], rules[[All, 2]]]];



    map = (#[[2, 1]] -> WLLeaf[formAStringX[#[[1]]]]) & /@ placeholders;
 
 
    map = With[{expr = #[[2]]}, #[[1]] -> ToString[expr, InputForm]] & /@ map;

    StringSplit[StringRiffle[formAString /@ CodeParse[StringReplace[pureWLCode, map]][[2]], ""], "\n"]

]

formAString[CallNode[LeafNode[type_, head_, c___], content_, garbage___]] := formAString[type, head, content]

formAString[CallNode[LeafNode[type_, head_, c___]]] := formAString[type, head]
formAString[LeafNode[type_, head_, c___]] := formAString[type, head]
formAString[CallNode[CallNode[c___], args_, garbage_]] := StringTemplate["``[``]"][formAString[CallNode[c]], StringRiffle[{formAString /@ args} // Flatten, ", "]]

formAString[Symbol, "CompoundExpression", content_] := 
 Block[{level = If[NumberQ[level], level + 1, 1]},
  StringJoin @@ ({"\n",
      (Identity[({Table["&emsp;&emsp;&emsp;", {i, level}], formAString[#], ";", 
            "\n"} & /@ Drop[content, -1])]), 
      If[formAString[content // Last] == "Null", 
       Table["&emsp;&emsp;&emsp;", {i, level - 1}], {Table["&emsp;&emsp;&emsp;", {i, level}], 
        formAString[content // Last], "\n", 
        Table["&emsp;&emsp;&emsp;", {i, Max[0, level - 1]}]}]} // Flatten)
  
  ]

formAString[Symbol, "Power", args_] := StringTemplate["``<sup>``</sup>"][formAString[args[[1]]], formAString[args[[2]]] ];
formAString[Symbol, "Times", args_] := StringRiffle[formAString /@ args, " "];

formAString[Symbol, "Comment", args_] := StringTemplate["``\n"][StringReplace[formAString[args[[1]]], "\""->""]];
formAString[Symbol, "Set", args_] := StringTemplate["`` = ``"][formAString[args[[1]]], formAString[args[[2]]] ];
formAString[Symbol, "Rule", args_] := StringTemplate["`` -> ``"][formAString[args[[1]]], formAString[args[[2]]] ];
formAString[Symbol, "SetDelayed", args_] := StringTemplate["`` := ``"][formAString[args[[1]]], formAString[args[[2]]] ];
formAString[Symbol, "Plus", args_] := StringTemplate["`` + ``"][formAString[args[[1]]], formAString[args[[2]]] ]
formAString[Symbol, "List", args_] := "{" <> StringRiffle[{formAString /@ args} // Flatten, ", "] <> "}";
formAString[Symbol, "Null", nul__] := ";"
formAString[Symbol, "Function", list_] := If[Length[list] === 1, 
   StringTemplate["(``)&"][formAString[list // First]], 
   StringTemplate["``[``]"][HighlightTagStyle["DownValue"]["Function"], StringRiffle[{formAString /@ list} // Flatten, ", "]]
];
formAString[Symbol, "Slot", level_] := HighlightTagStyle["Slot"][StringTemplate["#``"][First[formAString /@ level]]]
formAString[Symbol, "Null"] := "Null"
formAString[Symbol, x_String, args_] := StringTemplate["``[``]"][HighlightTagStyle["DownValue"][x], StringRiffle[{formAString /@ args} // Flatten, ", "]]
formAString[Symbol, x_String] := HighlightTagStyle["Symbol"][x]
formAString[String, x_String] := HighlightTagStyle["String"][x]
formAString[Integer, i_] := HighlightTagStyle["Number"][ToString[i]]
formAString[Real, i_] := HighlightTagStyle["Number"][ToString[i]]
formAString[Symbol, "Pattern", args_] := HighlightTagStyle["Pattern"][formAString[args[[1]]] <> "_" <> formAString[args[[2]]]]
formAString[Symbol, "Blank", args_] := ""

formAString[Symbol, "JerryI`WLX`Highlighter`Private`WLLeaf", args_] := StringReplace[(args//First)[[2]]//ToExpression, {}];

listLength[level_][list_] := (Print[list]; Length[list] == level)


(* atoms *)
formAStringX["Singular", "Number", token_] := HighlightTagStyle["Tag"]["&lt;"]<>HighlightTagStyle["Number"][token["head"]]<>HighlightTagStyle["Tag"]["/&gt;"]

(* atoms *)
(* any WL expressions returns WL expression *)
formAStringX["Singular", "Expression", token_] := With[{
    block = (StringJoin[HighlightTagStyle["Block"][#[[1]]], "=", HighlightTagStyle["None"]["{"], HighlightTagStyle["BlockArg"][#[[2]]], HighlightTagStyle["None"]["}"]] & /@ token["block"])
},
    HighlightTagStyle["Tag"]["&lt;"]<>HighlightTagStyle["XSymbol"][token["head"]]<>If[Length[block]>0," "<>StringRiffle[block, " "]<>" ",""]<>HighlightTagStyle["Tag"]["/&gt;"]
]
formAStringX["Normal", "Expression", token_] := With[{
    block = (StringJoin[HighlightTagStyle["Block"][#[[1]]], "=", HighlightTagStyle["None"]["{"], HighlightTagStyle["BlockArg"][#[[2]]], HighlightTagStyle["None"]["}"]] & /@ token["block"])
},
    HighlightTagStyle["Tag"]["&lt;"]<>HighlightTagStyle["XSymbol"][token["head"]]<>If[Length[block]>0," "<>StringRiffle[block, " "]<>" ",""]<>HighlightTagStyle["Tag"]["&gt;"]<>HighlightTagStyle["Tag"]["&lt;/"]<>HighlightTagStyle["XSymbol"][token["head"]]<>HighlightTagStyle["Tag"]["&gt;"]
]
formAStringX["Nested", "Expression", token_, args_] := With[{
    block = (StringJoin[HighlightTagStyle["Block"][#[[1]]], "=", HighlightTagStyle["None"]["{"], HighlightTagStyle["BlockArg"][#[[2]]], HighlightTagStyle["None"]["}"]] & /@ token["block"])
},
    Block[{level = If[NumberQ[level], level+1, 1]}, HighlightTagStyle["Tag"]["&lt;"]<>HighlightTagStyle["XSymbol"][token["head"]]<>If[Length[block]>0," "<>StringRiffle[block, " "]<>" ",""]<>HighlightTagStyle["Tag"]["&gt;"]<>"\n"<>(args//applyTabs[level])<>"\n"<>HighlightTagStyle["Tag"]["&lt;/"]<>HighlightTagStyle["XSymbol"][token["head"]]<>HighlightTagStyle["Tag"]["&gt;"]]
]

(* any HTML tags results in strings *)
formAStringX["Normal", "HTML", token_] := With[{
   props = (StringJoin[HighlightTagStyle["Common"][#[[1]]], "=", HighlightTagStyle["String"]["\"{"], HighlightTagStyle["Symbol"][#[[2]]], HighlightTagStyle["String"]["}\""]] & /@ token["properties"]),
   commns = StringJoin[HighlightTagStyle["Common"][#[[1]]], "=", HighlightTagStyle["String"]["\""], HighlightTagStyle["String"][#[[2]]], HighlightTagStyle["String"]["\""]] & /@ token["common"]
  },
   StringJoin[HighlightTagStyle["Tag"]["&lt;"], HighlightTagStyle["XML"][token["head"]], " ", StringRiffle[Join[props, commns], " "], HighlightTagStyle["Tag"]["&gt;&lt;/"], HighlightTagStyle["XML"][token["head"]], HighlightTagStyle["Tag"]["&gt;"]]
] ;

(* any HTML tags results in strings *)
formAStringX["Singular", "HTML", token_] := With[{
   props = (StringJoin[HighlightTagStyle["Common"][#[[1]]], "=", HighlightTagStyle["String"]["\"{"], HighlightTagStyle["Symbol"][#[[2]]], HighlightTagStyle["String"]["}\""]] & /@ token["properties"]),
   commns = StringJoin[HighlightTagStyle["Common"][#[[1]]], "=", HighlightTagStyle["String"]["\""], HighlightTagStyle["String"][#[[2]]], HighlightTagStyle["String"]["\""]] & /@ token["common"]
  },
   StringJoin[HighlightTagStyle["Tag"]["&lt;"], HighlightTagStyle["XML"][token["head"]], " ", StringRiffle[Join[props, commns], " "], HighlightTagStyle["Tag"]["/&gt;"]
  ]
] ;

(* regular text *)
formAStringX["Singular", "Text", token_] := HighlightTagStyle["innerText"][token["content"]] 

(* any HTML tags results in strings *)
formAStringX["Nested", "HTML", token_, args_] :=Block[{level = If[NumberQ[level], level+1, 1]}, With[{
   props = (StringJoin[HighlightTagStyle["Common"][#[[1]]], "=", HighlightTagStyle["String"]["\"{"], HighlightTagStyle["Symbol"][#[[2]]], HighlightTagStyle["String"]["}\""]] & /@ token["properties"]),
   commns = StringJoin[HighlightTagStyle["Common"][#[[1]]], "=", HighlightTagStyle["String"]["\""], HighlightTagStyle["String"][#[[2]]], HighlightTagStyle["String"]["\""]] & /@ token["common"]
  },
   StringJoin[HighlightTagStyle["Tag"]["&lt;"], HighlightTagStyle["XML"][token["head"]], " ", StringRiffle[Join[props, commns], " "], HighlightTagStyle["Tag"]["&gt;"], "\n", applyTabs[level][{ToString /@ args} // Flatten], "\n",HighlightTagStyle["Tag"]["&lt;/"], HighlightTagStyle["XML"][token["head"]], HighlightTagStyle["Tag"]["&gt;"]
  ]
]];

formAStringX[Token["Normal", head_, tail_]] := formAStringX["Normal", head["atom"], head] ;

formAStringX[Token["Singular", head_]] := formAStringX["Singular", head["atom"], head] ;


formAStringX[Token["Nested", head_, tail_, TokenGroup[childred_]]] := formAStringX["Nested", head["atom"], head, Block[{level = If[NumberQ[level], level+1, 1]}, (formAStringX /@ childred) ]];

formAStringX[Token["Nested", head_, tail_, child_]] := formAStringX["Nested", head["atom"], head, Block[{level = If[NumberQ[level], level+1, 1]}, (formAStringX /@ {child}) ]];

(* bufix *)
formAStringX[JerryI`WLX`Private`TokenGroup[childred_]] := StringRiffle[formAStringX /@ childred, "\n"]


applyTabs[level_][str_String] := StringRiffle[Flatten[{Table["&emsp;&emsp;&emsp;", {i, level}], #} &/@StringSplit[str, "\n"]], ""]
applyTabs[level_][str_List] := StringRiffle[Flatten[{Table["&emsp;&emsp;&emsp;", {i, level}], #} &/@str], ""]

(* style will be applied as a WLX function! then one can expecilitly spcify *)

End[]

EndPackage[]