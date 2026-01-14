BeginPackage["JerryI`WLX`", {"CodeParser`"}]

ProcessString::usage = "ProcessString[str_String] processes str to a plain WL expressions"
ToStringRiffle::usage = "ToString, but turns arrays into a string as well"
Dummy::usage = "dummy analogue from HTML, but acts as ToStringRiffle"

Begin["`Private`"]

ProcessString[pstr_String, OptionsPattern[]] := Module[{str, open, close, singular, commentsList = {}, tokens, tree, placeholders, escapedCode, pureWLCode, map},
    (* escape HTML comments *)
    {str, commentsList} = escapeComments[pstr];
    
    (* escape the area marked by user *)
    {str, escapedCode} = escape[str];

    
    (* three types of HTML tags *)
    {open, close, singular} = parseTags[str];

    If[Length[open] > 0 || Length[close] > 0 || Length[singular] > 0,

      (* parse all tokens *)
      tokens = SortBy[
         Join[tokenizer[#, 1, str] & /@ open, tokenizer[#, 0, str] & /@ singular, 
          tokenizer[#, -1, str] & /@ close], #["pos"][[1]] &];


      fetchInnerText[tokens, str, OptionValue["Trimmer"], commentsList];
      tokens = Join[tokens, fetchInnerText[tokens, str, OptionValue["Trimmer"], commentsList]];
      tokens = SortBy[tokens, #["pos"][[1]] &];

      

      (* build AST tree *)
      tree = ast[tokens, str];
      If[FailureQ[tree], Return[$Failed] ];

      (* generate rules of string replacement *)
      placeholders = {generatePlaceholders[tree]}//Flatten;


      (* generate sanitized list of expressions *)
      pureWLCode = ToExpression[#, InputForm, Hold2] & /@ SplitExpression[
          With[{rules = Values[placeholders]},
              StringReplacePart[str, rules[[All, 1]], rules[[All, 2]]]
          ]
      ];

      (* construct WL expression from WLX *)
      map = (ToExpression[#[[2, 1]]] -> constructWL[#[[1]]]) & /@ placeholders;
      map = With[{expr = #[[2]]}, #[[1]]->Hold2[expr]] & /@ map;

      (* restore dangerous functions *)

      map = map /. escapedCode;

      ClearAll /@ escapedCode[[All,1]];

      map = map  //. {FakeFlatten -> Flatten, StringRiffleFake -> StringRiffle, 
                      StringJoinFake -> StringJoin, FakeBlock -> Block, FakeHold[x_] :> x,
                      ToStringFake -> ToStringRiffle
                  };

      


      (* hydrate with WLX the original code again *)
      pureWLCode = pureWLCode /. map;
    ,
      (* normal WL code with no tags*)
      pureWLCode = ToExpression[#, InputForm, Hold2] & /@ SplitExpression[
          pstr
      ];
    ];

    
    

    (* EXIT::1 *)
    (* return the results if no localization is specified ! *)
    If[!TrueQ[OptionValue["Localize"]], 
      With[{r = pureWLCode},
        Return[ FakeHold[CompoundExpression @@ r] /. {Hold2 -> Identity} /. {FakeHold -> Hold}, Module]
      ];
    ];

    (* EXIT::2 *)
    (* perform localization of variables and return the result ! *)
    convertToModule[extractLocalVariables[pureWLCode], pureWLCode] /. {Hold2 -> Identity} /. {FakeHold -> Hold}  
]

IdentityTransform[a_] := a

System`WLXForm;

$BoxForms = Append[$BoxForms, WLXForm]

(* identity transformation *)
WLXForm /: MakeBoxes[any_, WLXForm] := any
WLXForm /: FormBox[expr_, WLXForm] := expr 

Options[ProcessString] = {
  "Localize" -> False,
  "Trimmer" -> Trimmer,
  "Rules" -> {}
}


(* remove white spaces, but keep the separations <b></b>_word *)
Trimmer = Function[str, 
StringReplace[str, {
  RegularExpression["\\A[\\n|\\t|\\r]*( *)([\\w|:|\\/|.|\\d]?)"] :> If[StringLength["$2"]===0, "", If[StringLength["$1"] > 0, " $2", "$2"]],
  RegularExpression["([\\w|:|\\/|.|\\d]?)( *)[\\r|\\n| |\\t]*\\Z"] :> If[StringLength["$1"]===0, "", If[StringLength["$2"] > 0, "$1 ", "$1"]]
}]
];

escapeComments[str_String] := Module[{map = {}, new},
  new = StringReplace[str, RegularExpression["\\<\\!\\-\\-([^\\!|\\<|\\>]*)\\>"] :> With[{uid = CreateUUID[], body = "$1"},
    AppendTo[map, ("WLXCMNT["<>uid<>"]") -> ("<!--"<>body<>">")];
    ("WLXCMNT["<>uid<>"]")
  ]];
  {new, map}
]

parseTags[str_String] := {
  StringPosition[str, RegularExpression["\\<(\\w*)(\\s*(((\\w|-)*)=\\\"([^\"]+)\")*((\\w*)=\\{([^\\<\\>]+)\\})*)*\\>"]],
  StringPosition[str, RegularExpression["(\\<\\/[^\\<|\\>|\\/]*\\>)"]],
  StringPosition[str, RegularExpression["(\\<[^\\<|\\>]*\\/\\>)"]]
}

escape[str_String] := Module[{rules = {}, populate, newstr},
  
  populate = (rules = {rules, #}) &;
  newstr = StringReplace[str, RegularExpression["<Escape>((?:(?!<Escape>)[\\s\\S])*?)<\\/Escape>"] :> escapeReplacement[populate, "$1"]];
  
  {newstr, rules // Flatten}
]

escapeReplacement[handler_, pattern_] := With[{unique = Unique["EscapedExpr"]},
  handler[unique -> pattern]; 
  "<"<>ToString[unique, InputForm]<>"/>"
]

(*** Tokenizer for the WLX subset ***)

(* regexp for the inset of the WL expression *)
wlinset = "[\\w|@|\\[|\\]|,|#|)|(|\\>|;|:|\\<|\\||\\/|\\+|\\$|{|}|\\\"|\\-|\\.|\\s|\\d]*";

tokenizer[s_, r_, str_] := 
 With[{element = 
    (* HTML tag as a full thing *)
    
    StringTake[StringDrop[str, s[[1]] - 1], s[[2]] - s[[1]] + 1]
  },

  With[{
    (* the head of a tag (for WL functions/components starts from Capital letter) *)
    head = 
     StringCases[element, 
       RegularExpression["\\<\\/?([^\\<|\\>|\\/|\\s]*)[^\\<|\\>|\\/]?[^\\<|\\>]*[^\\<|\\>|\\/]*\\/?\\>"] -> "$1" ] // First,

    (* parameters passed as title={Title}, usually constants for the components *)     
    block = 
     StringCases[element, 
      RegularExpression["(\\w*)=\\{("<>wlinset<>")\\}"] -> ("$1" -> "$2") ],

    (* HTML/XML properties passed as class="{Class}", usually constants for styles and etc *)  
    prop = 
     StringCases[element, 
      RegularExpression["([\\w|\\-]*)=\"([^\"|=|{|}]*)\\{("<>wlinset<>")\\}([^\"|=|{|}]*)\""] -> ("$1" -> {"$2", "$3", "$4"}) ],

    (* static properties like style="background-color: red;" *)
    common = 
     StringCases[element, 
      RegularExpression[
        "([\\w|\\-]*)=\\\"([\\w|\\(|\\)|=|\\;|\\^|\\:|\\s|\\d|\\%|#|\\.|\\-|\\,|\\?|\\/|\\@]*)\\\""] -> ("$1" -> "$2") ]
    },

    With[{firstH = StringTake[head, 1]},
      <|"pos" -> s, "type" -> r, 
       "atom" -> 
        If[StringMatchQ[head, RegularExpression["[\\d|\\.]*"]], "Number", If[(UpperCaseQ[firstH] || firstH === "$"), "Expression", "HTML"]], 
       "head" -> head, "native" -> (UpperCaseQ[firstH] || firstH === "$"), 
       "block" -> block, "properties" -> prop , 
       "common" -> common|>
    ]
   ]
  ]

(* fetch the rest of the data in a form of text (trimmed strings). 
   it can be <div>Hi!</div> -> Hi!
 *)

fetchInnerText = Function[{t, str, trimmer, htmlcomments}, 
   Select[
    Module[{bra = 0},
      Table[
       bra += t[[i]]["type"];
       
       If[bra == 0, Missing[],
        With[{l = t[[i]]["pos"][[2]], r = t[[i + 1]]["pos"][[1]]},
         
         <|"pos" -> {l + 1, r - 1}, "atom" -> "Text", "block" -> {}, 
          "head" -> "WText", "type" -> 0, "native" -> True, 
          "content" -> StringReplace[(StringTake[StringDrop[str, l], r - l - 1] // 
             trimmer), htmlcomments]|>
         ]
        ]
       , {i, Length[t] - 1}]] // DeleteMissing, 
    StringLength[#["content"]] > 0 &]
   ];

(*** Absctract Syntax Tree Builder   ***)
(*   goest one time thorugh the tokens *)

(* all nested groups flats to zero-level *)
(* nested groups are fobidden. do not use them for List[List[]]! *)
TokenGroup[{Token[A___], TokenGroup[B_], n___}] := TokenGroup[Flatten[{Token[A], B, n}]]

(* i :> WL *)

ast::nonballanced = "Non ballanced: ``";

ast[tokens_List, original_String] := 
 Module[{level = 0, index = 1, bra, depth, head, exp = {}, last = {}, group, tail},

  If[AnyTrue[tokens, FailureQ],
    Return[$Failed];
  ];

  (* bra stands for the level of hierarch. *)
  bra = 0; depth = 0;
  If[Length[tokens] == 0, Return[Null]];
  
  (* if this is a singular token, i.e. <br/> *)
  If[(head = First[tokens])["type"] == 0, 
   If[Length[tokens] > 1, 

    (* process the rest independently *)
    With[{processed = ast[Drop[tokens, 1], original]},
      If[FailureQ[processed], Return[processed] ];
      Return[TokenGroup[Flatten[{Token["Singular", head], processed}] ] ]
    ] 
   , 

    (* return that one *)
    Return[Token["Singular", head]]];
   ];
  
  (* if our tokens are non-singular *)
  
  bra = 1;
  Do[
  
   With[{t = tokens[[i]] (* current tail (or head, it depends) of the tag *)},
    bra += t["type"];

    (* if the level of nesting goes back to the original position *)
    If[bra == 0,
     (* check if we found the closing tag of one we started with*)
     If[t["head"] == head["head"],
      
      (* extract the entire expression undeneath *)
      exp = Take[tokens, i];
      last = Drop[tokens, i];

      tail = t;
      Break[];
      
      ]
     ,

     (* we are still in the nested structure *)
     depth++;
     ];
    
    ]
   
   , {i, 2, Length[tokens]}];
  
  group = {};
  

  exp = If[depth > 0,
    (* if it contains subexpressions *)

    If[Length[exp] == 0,
      Message[ast::nonballanced, StringTemplate["tag `` at ``"][head["head"], head["pos"] ] ];
      Return[$Failed];
    ];

    

    Token["Nested", head, tail, 
     ast[Drop[Drop[exp, 1], -1], original]
    ]
    ,

    (* if not *)
    
      If[!AssociationQ[tail],
        Message[ast::nonballanced, StringTemplate["tag `` at `` probably is not closed"][head["head"], head["pos"] ] ];
        Return[$Failed];
      ];
    
      Token["Normal", head, tail]
    ];
  
  (* parse the rest *)
  If[Length[last] > 0,
    With[{processed = ast[last, original]},
      If[FailureQ[processed], Return[processed] ];

      TokenGroup[Flatten[{exp, processed}] ]
    ]
   
   ,
   exp
   ]
  
]

(*** Placeholder generator ***)
(* to prevent errors in a regular WL parsing procedure *)

generatePlaceholders[TokenGroup[group_]] := Module[{},
  generatePlaceholders[#] & /@ group
  ]

(* generates a rule for the StringReplace function in a form of 
    Token -> {new string, position} 
*)

generatePlaceholders[Token["Nested", head_, tail_, body_]] := 
 With[{uid = CreateUUID[]},
  Token["Nested", head, tail, body] -> {"WLX[\"" <> uid <> "\"]", {head["pos"] // First, tail["pos"] // Last}}
  ]

generatePlaceholders[Token["Normal", head_, tail_]] := 
 With[{uid = CreateUUID[]},
  Token["Normal", head, tail] -> {"WLX[\"" <> uid <> "\"]", {head["pos"] // First, tail["pos"] // Last}}
  ]

generatePlaceholders[Token["Singular", head_]] := 
 With[{uid = CreateUUID[]},
 (*was replaced from Normal to Singular??*)
  Token["Singular", head] -> {"WLX[\"" <> uid <> "\"]", head["pos"]}
  ]


(* helper function *)

ToStringRiffle[expr_] := ToString[expr];
Dummy[expr__] := StringRiffle[ToString /@ List[expr], ""];
ToStringRiffle[expr_List] := StringRiffle[ToString /@ expr, "\n"];


(***     Wolfram Script X Translator          ***)
(* construcs a valid WL expression from WLX AST *)

(* singular token -> singular WL *)
constructWL[Token["Singular", head_]] := Module[{},
   If[Length@head["block"] > 0,
     constructWL["Singular", head["block"] // blockToExpression, head["atom"], head]
    ,
    constructWL["Singular", head["atom"], head]
    ]
   ];

(* atoms *)
constructWL["Singular", "Number", token_] := ToExpression[token["head"]]

(* atoms *)
(* any WL expressions returns WL expression *)
constructWL["Singular", "Expression", token_] := With[{il=ToExpression[token["head"], InputForm, FakeHold]}, FakeHold[IdentityTransform[il]]]
constructWL["Normal", "Expression", token_] := With[{il=ToExpression[token["head"], InputForm, FakeHold]}, FakeHold[IdentityTransform[il[]]]]
constructWL["Nested", "Expression", token_, args_] := With[{il=ToExpression[token["head"], InputForm, FakeHold]}, FakeHold[IdentityTransform[il @@ Unevaluated[args]]]] 

(* if options are provided *)
constructWL["Singular", opts_List, "Expression", token_] := With[{il=ToExpression[token["head"], InputForm, FakeHold]}, FakeHold[IdentityTransform[il@@Unevaluated[opts]]]]
constructWL["Normal", opts_List, "Expression", token_] := With[{il=ToExpression[token["head"], InputForm, FakeHold]}, FakeHold[IdentityTransform[il@@Unevaluated[opts]]]]
constructWL["Nested", opts_List, "Expression", token_, args_] := With[{il=ToExpression[token["head"], InputForm, FakeHold]}, With[{a = Join[args, opts]}, FakeHold[IdentityTransform[il @@ Unevaluated[a]]]]] 



(* any HTML tags results in strings *)
constructWL["Normal", "HTML", token_] := With[{
   props = (StringJoinFake[#[[1]], "=\"", #[[2,1]], ToExpression[#[[2,2]], InputForm, FakeHold@*ToString], #[[2,3]], "\""] & /@ token["properties"]),
   commns = StringJoinFake[#[[1]], "=\"", #[[2]], "\""] & /@ token["common"]
 },
   StringJoinFake["<", token["head"], " ", StringRiffleFake[Join[props, commns], " "], "></", token["head"], ">"]
];

(* any HTML tags results in strings *)
constructWL["Singular", "HTML", token_] := With[{
   props = (StringJoinFake[#[[1]], "=\"", #[[2,1]], ToExpression[#[[2,2]], InputForm, FakeHold@*ToString], #[[2,3]], "\""] & /@ token["properties"]),
   commns = StringJoinFake[#[[1]], "=\"", #[[2]], "\""] & /@ token["common"]
  },
   StringJoinFake["<", token["head"], " ", StringRiffleFake[Join[props, commns], " "], "/>"
  ]
];

(* regular text *)
constructWL["Singular", "Text", token_] := token["content"]

(* any HTML tags results in strings *)
constructWL["Nested", "HTML", token_, args_] := With[{
   props = (StringJoinFake[#[[1]], "=\"", #[[2,1]], ToExpression[#[[2,2]], InputForm, FakeHold@*ToString], #[[2,3]], "\""] & /@ token["properties"]),
   commns = StringJoinFake[#[[1]], "=\"", #[[2]], "\""] & /@ token["common"]
  },
   StringJoinFake["<", token["head"], " ", StringRiffleFake[Join[props, commns], " "], ">", StringRiffleFake[{ToStringFake /@ args} // FakeFlatten, ""], "</", token["head"], ">"
  ]
];

constructWL[Token["Normal", head_, tail_]] := 
   If[Length@(head["block"]) > 0,
    constructWL["Normal", head["block"] // blockToExpression, head["atom"], head]
    ,
    constructWL["Normal", head["atom"], head]
];


constructWL[Token["Nested", head_, tail_, TokenGroup[childred_]]] := 
  Module[{},
   If[Length@head["block"] > 0,
     constructWL["Nested", head["block"] // blockToExpression, head["atom"], head, (constructWL /@ childred)]
    ,
     constructWL["Nested", head["atom"], head, (constructWL /@ childred)]
    ]
];

constructWL[Token["Nested", head_, tail_, child_]] := 
   If[Length@head["block"] > 0,
     constructWL["Nested", head["block"] // blockToExpression, head["atom"], head, (constructWL /@ {child})]
    ,
     constructWL["Nested", head["atom"], head, (constructWL /@ {child})]
];

(*** Language manipulation tools ***)

convertToModule[vars_, body_] := vars /. _@{v__} :> FakeHold[Module[{v}, CompoundExpression @@ Join[{garbageList[FakeHold[vars]]}, body]]]
convertToModule[Hold2[{}], body_]    := FakeHold[CompoundExpression @@ body]

(*** garbage collection ***)

garbageCollection = {};

garbageList[list_] := (
  AppendTo[garbageCollection, list];
)


extractLocalVariables[exprs_List] := Module[{localVariables = {}},
  (* capture all set and setdelayed in the top-level *)



  exprs /. {
   Hold2[CompoundExpression[Set[List[a__Symbol], b_], Null ] ] :> With[{list = List[a]}, AppendTo[localVariables, Hold2[#]]&/@list], 
   Hold2[Set[a_, b_]] :> AppendTo[localVariables, Hold2[a]], 
   Hold2[SetDelayed[a_, b_]] :> AppendTo[localVariables, Hold2[a]], 
   Hold2[CompoundExpression[SetDelayed[a_, b_], args__]] :> AppendTo[localVariables, Hold2[a]],
   Hold2[CompoundExpression[Set[a_, b_], args__]] :> AppendTo[localVariables, Hold2[a]]
  };


  
  (* extract symbol names from DownValues and OwnValues *)
  localVariables = 
  If[
    With[{s = Extract[#, {1, 0}, Unevaluated]},
     s === Symbol
    ],
      #
  ,
      Extract[#, {1, 0}, Hold2]
  ] & /@ localVariables;

  localVariables = Complement[localVariables, {Hold2[Options], Hold2[List]}];

 

  (* flatten the list *)
  With[{l = DeleteDuplicates[localVariables]},
    FakeHold[l]
  ] /. {Hold2[x_] :> x} /. {FakeHold -> Hold2}
]


(* split expressions in the original Wolfram Code *)

SplitExpression[astr_] := 
  With[{str = StringReplace[astr, {}]}, 
   Select[
    Select[(StringTake[str, 
         Partition[Join[{1}, #, {StringLength[str]}], 2]] &@
       Flatten[{#1 - 1, #2 + 1} & @@@ 
         Sort@
          Cases[
           CodeParser`CodeConcreteParse[str, 
             CodeParser`SourceConvention -> 
              "SourceCharacterIndex"][[2]], 
           LeafNode[Token`Newline, _, a_] :> 
            Lookup[a, Source, Nothing]]]), 
     StringQ], (StringLength[#] > 0) &]]; 

(* utils for making modules/blocks *)
SetAttributes[FakeSet, HoldAll]
SetAttributes[FakeHold, HoldAll]
SetAttributes[Hold2, HoldAll]
SetAttributes[FakeBlock, HoldAll]

blockToExpression[input_List] := With[{},
  (#[[1]] -> ToExpression[#[[2]], InputForm, FakeHold]) &/@ input
]

makeBlock[vars_List, inner_] :=
 (With[{c = vars /. {
    Rule[x_, y_] :> 
        With[{a = ToExpression[x, InputForm, FakeHold], b = ToExpression[y, InputForm, FakeHold]},
         FakeSet[a, b]
        ]}
    },

   With[{v = Hold2[c] /. {FakeHold[x_] :> x} /. {FakeSet :> Set}},
    FakeBlock[v, 
       ArgsPlaceHolder] /. {Hold2[x_] -> x} /. {ArgsPlaceHolder -> 
       FakeHold[inner]}
    ]
   ])


End[]
EndPackage[]
