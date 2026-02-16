BeginPackage["CoffeeLiqueur`Extensions`FrontendObject`"]

(* we have to expose them to System, otherwise Boxes won't work from Mathematica's packages *)

System`CreateFrontEndObject;
System`FrontEndRef;
System`FrontEndExecutable;
System`FrontEndVirtual;

CreateFrontEndObject::usage = "CreateFrontEndObject[expr_, uid_, opts] to force an expression to be evaluated on the frontend inside the container. There are two copies (on Kernel, on Frontend) can be specified using \"Store\"->\"Kernel\", \"Frontend\" or All (by default)"
FrontEndRef::usage = "A readable representation of a stored expression on the kernel"
FrontEndExecutable::usage = "A representation of a stored expression on the frontend"

FrontEndVirtual::usage = ""

Begin["`Internal`"]



$MissingHandler[_, _] := $Failed

(* predefine for the future *)
System`WLXForm;

Objects = <||>
Symbols = <||>


Compressed[string_String, {"ExpressionJSON", "ZLIB"}] := ImportByteArray[ByteArray[Developer`RawUncompress[BaseDecode[string]//Normal]], "ExpressionJSON"]

compress[expr_, f: {"ExpressionJSON", "ZLIB"}] := Hold[expr]
compress[expr_, f: {"ExpressionJSON", "ZLIB"}] := With[{arr = Normal[ExportByteArray[expr, "ExpressionJSON"] ]},
  With[{data = BaseEncode[ByteArray[Developer`RawCompress[arr] ] ]},
    Compressed[data, f] // Hold
  ]
] /; (ByteCount[expr] > 0.1 * 1024 * 1024);

CreateFrontEndObject[expr_, uid_String, OptionsPattern[] ] := With[{},
    With[{
        data = Switch[OptionValue["Store"]
            , "Kernel"
            , <|"Private" -> compress[expr, {"ExpressionJSON", "ZLIB"}]|>

            , "Frontend"
            , <|"Public"  -> compress[expr, {"ExpressionJSON", "ZLIB"}]|>

            ,_
            , <|"Private" -> compress[expr, {"ExpressionJSON", "ZLIB"}], "Public" :> Objects[uid, "Private"]|>
        ]
    },
        If[!AssociationQ[Objects], 
            Echo["Frontend Objects >> FATAL Error >> Objects are no longer an association"];
            Echo["Rebuilding..."];
            Objects = <||>;
        ];

        If[KeyExistsQ[Objects, uid],
            Objects[uid] = Join[Objects[uid], data ];    
        ,
            Objects[uid] = data;    
        ];    
    ];
    
    FrontEndExecutable[uid]
]

CreateFrontEndObject[expr_, opts: OptionsPattern[] ] := CreateFrontEndObject[expr, CreateUUID[], opts]

Options[CreateFrontEndObject] = {"Store" -> All}

FrontEndRef[uid_String] := If[KeyExistsQ[Objects, uid], 
    Objects[uid, "Private"] // ReleaseHold
,
    $MissingHandler[uid, "Private"] // ReleaseHold
]

FrontEndExecutable /: MakeBoxes[FrontEndExecutable[uid_String], StandardForm] := RowBox[{"(*VB[*)(FrontEndRef[\"", uid, "\"])(*,*)(*", ToString[Compress[Hold[FrontEndExecutable[uid]]], InputForm], "*)(*]VB*)"}]

GetObject[uid_String] := With[{},
    (*Echo["Getting object >> "<>uid];*)
    If[KeyExistsQ[Objects, uid],
        Objects[uid, "Public"]
    ,
        $Failed
    ]
]

End[]


Begin["`Tools`"]

UIObjects;
ListObjects[] := Keys[CoffeeLiqueur`Extensions`FrontendObject`Internal`Objects]


End[]

EndPackage[]