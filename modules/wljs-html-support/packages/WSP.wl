(* ::Package:: *)

BeginPackage["WSP`"]


LoadPage::usage = 
"LoadPage[path_String, vars_List, \"Base\"->\"BasePath\"] \
process a file located at path relative to the BasePath and returns a string. \
Use vars to provide data to the loading page."


LoadString::usage = 
"LoadPage[s_String, vars_List] process a string and returns string. \
Use vars to provide data to the page."


WSPEngine::usage = 
"SetOptions[WSPEngine, \"Cache\"->False] disables caching. \
One can set it to True, Automatic or specific interval in a form of a string."


WSPLoad::usage = 
"Alias for LoadPage"


Begin["`Private`"]


(* smart caching. credits https://github.com/KirillBelovTest *)
SetAttributes[wcache, HoldFirst]


wcache[expr_, date_DateObject] := (
	wcache[expr, {"Date"}] = date; 
	wcache[expr, date] = expr
);

wcacheInterval = "Minute"


wcache[expr_, interval_String: "Minute"] := (
	If[DateObjectQ[wcache[expr, {"Date"}]] && DateObject[Now, interval] != wcache[expr, {"Date"}], 
		wcache[expr, wcache[expr, {"Date"}]] =.]; 
	wcache[expr, DateObject[Now, interval]]
);


pcache = wcache;


(*replacement for web objects*)
webrules = {
    Graphics :> (ExportString[#, "SVG"] &@*Graphics),
    Graphics3D :> (ExportString[#, "SVG"] &@*Graphics3D)
};


WSPEngine /: SetOptions[WSPEngine, opts___] := With[{o = List[{opts}//Flatten] // Association},
    If[KeyExistsQ[o, "Cache"], 
        SetCache[o["Cache"]];
    ];

    If[KeyExistsQ[o, "ExpressionReplacements"],
        webrules = o["ExpressionReplacements"];
    ];
]

WSPLoad = LoadPage

SetCache[False] := pcache = Function[x, x]
SetCache[Automatic] := (pcache = wcache; wcacheInterval = "Minute")
SetCache[True] := (pcache = wcache; wcacheInterval = "Minute")
SetCache[None] := pcache = Function[x, x]
SetCache[interval_String] := (pcache = wcache; wcacheInterval = interval)

findComponent[path_] := If[DirectoryQ[path], FileNameJoin[{path, "index.wsp"}], path]

URLPathToFileName[urlPath_String] := 
FileNameJoin[FileNameSplit[StringTrim[urlPath, "/"]]]; 

LoadPage[p_, vars_: {}, OptionsPattern[]]:=
    Block[vars,
        If[StringQ[Global`$WSPPublic] && StringLength[OptionValue["Base"]] == 0,
            With[{path = FileNameJoin[{Global`$WSPPublic, URLPathToFileName[p]}]},
                Process@(pcache[ With[{stream = Import[path // findComponent, "Text"]}, AST[stream, {}, "Simple"] ], wcacheInterval ])
            ]
        ,
            Block[{Global`$WSPPublic = OptionValue["Base"]},
                With[{path =If[StringLength[Global`$WSPPublic] > 0, FileNameJoin[{Global`$WSPPublic, URLPathToFileName[p]}], URLPathToFileName[p] ]  },
                    Process@(pcache[ With[{stream = Import[path // findComponent, "Text"]}, AST[stream, {}, "Simple"] ], wcacheInterval ])
                ]            
            ]
        ]
    ];


(*LoadPage[p_, opts_: OptionsPattern[]] := LoadPage[p, {}, opts]*)


Options[LoadPage] = {"Base" -> ""};


LoadString[p_, vars_:{}]:=
    Block[vars,
        Process@AST[p, {}, "Simple"]
    ];    


SetAttributes[LoadPage, HoldRest];
SetAttributes[LoadString, HoldRest];


StringFix[str_]:=StringReplace[str,Uncompress["1:eJxTTMoPSmNiYGAoZgESQaU5qcGMQIYSmFQHAFYsBK0="]];
StringUnfix[str_]:=StringReplace[str,Uncompress["1:eJxTTMoPSmNiYGAoZgESQaU5qcGMQIY6mFQCAFZKBK0="]];


AST[s_, init_ : {}, "Simple"] := Module[
{code = init, text = "", rest = "", last = "", c = "", exp = "", bra = 0, depth = 0, substream, length},
    (*extract everything before *)

    If[s == "", Return[Flatten@code, Module]];

    text = Null;
    length = StringLength[s];

    (*like in C style, probably it will be slower*)

    Do[
         If[StringTake[s, {i,i+4}] == "<?wsp",
             text = StringTake[s, i-1];
             rest = StringDrop[s, i+4];
             Break[];
         ]
         , {i, length-4}    
    ];

    (*text = StringExtract[s, "<?wsp" -> 1]; 
    rest = StringDrop[s, StringLength[text] + 5];*)

    (*pure HTML text*)
    If[TrueQ[text == Null],
        Return[Flatten@{code, "HTML" -> s}, Module];
    ];

    (*text = StringTrim[text];*)
    code = {code, "HTML" -> text};

    (*extract the WF expression*)
    exp = Null;
    last = "";

    length = StringLength[rest];
    bra = 0; depth = 0;
    Do[
        If[StringTake[rest, {i,i+1}] == "?>",
            If[bra == 0,
                exp = StringTake[rest, i-1];
                last = StringDrop[rest, i+1];   
                Break[];     
            ,
                depth++
            ]

        ];

        If[StringPart[rest,i] == "[", bra++];
        If[StringPart[rest,i] == "]", bra--];    

        , {i, length-1}    
    ];

    If[TrueQ[exp == Null],
        Return[{"HTML" -> "Syntax error!"}, Module];
    ];

    If[depth > 0,
        code = {code, "MODULE" -> AST[exp, {}, "Module"]};
    ,
        code = {code, "WF" -> exp};
    ];

    (*for the rest of the code lines*)
    If[StringLength[last] == 0,
        Flatten@code
        ,  
        AST[last, code, "Simple"]
    ]
]


AST[s_, init_ : {}, "Module"] := Module[
{code = <||>, body = "", rest = "", text = "", c = "", exp = "", bra = 0, depth = 0, substream, subsubstream, tail="", head="", length},

    rest = Null;

    length = StringLength[s];

    (*like in C style, probably it will be slower*)
    Do[
        If[StringTake[s, {i,i+1}] == "?>",
            code["HEAD"] = StringTake[s, i-1];
            rest = StringDrop[s, i+1];
            Break[];
        ]
        , {i, length-1}    
    ];

    If[TrueQ[rest == Null], Return[<| "HEAD"->"", "BODY"->{"HTML"->"Syntax module error!"}, "TAIL"->"" |>, Module]];

    length = StringLength[rest];
    body = "";

    Do[
        If[StringTake[rest, {length-i+1-4, length-i+1}] == "<?wsp",
            code["TAIL"] = StringDrop[rest, length-i+1];
            body = StringTake[rest, length-i+1-4-1];
            Break[];
        ]
        , {i, length}    
    ];

    code["BODY"] = AST[body, {}, "Simple"];

    code
]


(* a pain in a neck that we have to safely escape quotes by replacing them via differnet symbols *)


Parse[x_] := 
  StringJoin[x["HEAD"] ,
   "{", (Switch[#[[1]], "HTML", StringJoin["+%+" , StringReplace[#[[2]], "\""->"-%-"], "+%+"], 
        "WF", #[[2]], "MODULE", Parse@#[[2]]] <> "," & /@ 
     Drop[x["BODY"], -1]) , (Switch[#[[1]], "HTML", 
       StringJoin["+%+" , StringReplace[#[[2]], "\""->"-%-"], "+%+"], "WF", #[[2]], "MODULE", 
       Parse@#[[2]]] &@Last[x["BODY"]]) , "}" , x["TAIL"]]

Process[x_] := 
  StringJoin@@ToString/@((
   Flatten@(Switch[#[[1]], "HTML", #[[2]], "WF", ReplaceAll[ToExpression@StringReplace[#[[2]], {"+%+" -> "\"", "\r\n" -> "", "-%-" -> "\\\""}], webrules], 
        "MODULE", ReplaceAll[ToExpression@StringReplace[Parse@#[[2]], {"+%+" -> "\"", "\r\n" -> "", "-%-" -> "\\\""}], webrules]] & /@ x)))

End[] (*`Private`*)


(* ::Section:: *)
(*End package*)


EndPackage[] 