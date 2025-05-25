BeginPackage["CoffeeLiqueur`Notebook`HTTPDownLoader`", {
    "KirillBelov`HTTPHandler`",
    "KirillBelov`HTTPHandler`Extensions`",
    "KirillBelov`Internal`"
}]
    
    Begin["`Internal`"]

    parseBytesRange[str_String] := Module[{matches},
      matches = StringCases[
        str,
        {
          "bytes=" ~~ a : DigitCharacter .. ~~ "-" ~~ b : DigitCharacter .. :> {a, b},
          "bytes=" ~~ a : DigitCharacter .. ~~ "-" :> {a, "Infinity"}
        }
      ];
      If[matches === {}, Missing["NoMatch"], ToExpression[matches[[1]]]]
    ]

    handler[m_][k_] := (
        Echo["Unsupported method!"];
        Echo[m];
        Echo[k];
    )

    handler["GET"][request_] := With[{path = URLDecode[request["Query", "path"] ], rangesString = Lookup[request["Headers"], "Range", False]},
        Echo["Downloader >> Get request"];

        If[rangesString === False,
            Return[ImportFile[path, "Base"->{Nothing}] ]
        ];

        With[{
            ranges = parseBytesRange[rangesString // StringTrim],
            size = Round[QuantityMagnitude[FileSize[path], "Bytes"] ]
        },
            Echo["Downloader >> Ranges: "<>ToString[ranges] ];
            

            With[{file = OpenRead[path, BinaryFormat->True]},
                ReadByteArray[file, ranges[[1]]];
                With[{body = ReadByteArray[file, Min[ranges[[2]], size-1]+1 ]},
                    Close[file];
                    Echo["Downloader >> Content-Length: "<>ToString[Length[body] ] ];
                    Echo["Downloader >> Content-Range: "<>(StringTemplate["bytes ``-``/``"][ranges[[1]], Min[ranges[[2]], size-1], size]) ];
                   
                    <|
                        "Body" -> body,
                        "Code" -> 206, 
                        "Headers" -> <|
                            "Content-Type" -> GetMIMEType[path], 
                            "Content-Length" -> Length[body],
                            "Content-Range" -> StringTemplate["bytes ``-``/``"][ranges[[1]], Min[ranges[[2]], size-1], size],
                            "Connection"-> "Keep-Alive", 
                            "Accept-Ranges" -> "bytes",
                            "Keep-Alive" -> "timeout=5, max=1000"
                        |>
                    |>                    
                ]
            ]
        ]
    
        
    ]

    handler["HEAD"][request_] := With[{path = URLDecode[request["Query", "path"] ]},
        Echo["Downloader >> Head request"];
        Echo[request];
        If[FileExistsQ[path],
            <|
                "Code" -> 200, 
                "Headers" -> <|
                    "Content-Type" -> GetMIMEType[path], 
                    "Accept-Ranges" -> "bytes",
                    "Content-Length" -> Round[QuantityMagnitude[FileSize[path], "Bytes"] ], 
                    "Connection"-> "Keep-Alive", 
                    "Keep-Alive" -> "timeout=5, max=1000"
                |>
            |>  
        ,
            <|
                "Code" -> 404, 
                "Headers" -> <|
                    "Content-Type" -> GetMIMEType[path], 
                    "Accept-Ranges" -> "bytes",
                    "Content-Length" -> 0, 
                    "Connection"-> "Keep-Alive", 
                    "Keep-Alive" -> "timeout=5, max=1000"
                |>
            |>  
        ]      
    ]

    module[OptionsPattern[] ] := With[{http = OptionValue["HTTPHandler"]},
        Echo["Downloads module was attached"];
        http["MessageHandler", "Downloader"] = AssocMatchQ[<|"Path" -> "/downloadFile/"|>] -> (handler[ #["Method"] ][#]&);
    ]

    Options[module] = {"HTTPHandler" -> Null}

    End[]

EndPackage[]

CoffeeLiqueur`Notebook`HTTPDownLoader`Internal`module