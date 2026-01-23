BeginPackage["CoffeeLiqueur`Extensions`API`", {
    "CoffeeLiqueur`Misc`Async`",
    "CoffeeLiqueur`Misc`Events`",
    "CoffeeLiqueur`Notebook`Transactions`",
    "CoffeeLiqueur`Misc`Events`Promise`",
    "CoffeeLiqueur`Misc`WLJS`Transport`",
    "CoffeeLiqueur`WLX`Importer`",
    "CoffeeLiqueur`HTTPHandler`",
    "CoffeeLiqueur`HTTPHandler`Extensions`",
    "CoffeeLiqueur`Internal`",
    "CoffeeLiqueur`Extensions`FrontendObject`"
}]


Begin["`Internal`"]

Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];
Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];

failure;


EventHandler[AppExtensions`AppEvents// EventClone, {
    "WLJSAPI:ApplyFunctionRequest" -> Function[handlerFunction,
        handlerFunction[apiCall];
    ]
}];

makeResponce[raw_] := If[MatchQ[raw, _failure],
        With[{},
            Echo["API Error >>"]; Echo[raw // First];
            <|
                "Body" -> ExportByteArray[raw // First, "JSON"], 
                "Code" -> 409, 
                "Headers" -> <|
                    "Content-Length" -> Length[ExportByteArray[raw // First, "JSON"] ], 
                    "Connection"-> "Keep-Alive", 
                    "Keep-Alive" -> "timeout=5, max=1000", 
                    "Access-Control-Allow-Origin" -> "*"
                |>
            |>
        ]       
      ,
        With[{r = ExportByteArray[raw, "JSON"]},
            <|
                "Body" -> r, 
                "Code" -> 200, 
                "Headers" -> <|
                    "Content-Length" -> Length[r], 
                    "Connection"-> "Keep-Alive", 
                    "Keep-Alive" -> "timeout=5, max=1000", 
                    "Access-Control-Allow-Origin" -> "*"
                |>
            |>
        ]      
      ];

HTTPAPICall[request_] := With[{type = request["Path"]},
    Echo["HTTP API Request >> "<>type];
    Echo["HTTP API Request Body >> "<>(request["Body"] // ByteArrayToString)];

    With[{raw = apiCall[Join[request, <|"Body"->ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"] |> ] ]},
      If[PromiseQ[raw], With[{id = raw[[1]]},
        $promises[id] = <|"ReadyQ" -> False|>;
        Then[raw, Function[result,
            $promises[id] = <|"ReadyQ" -> True, "Result"->result|>;
        ] ];

        makeResponce[<|"Promise"->id|>]
      ],
        makeResponce[raw]
      ]
    ]
]

apiCall[request_] := With[{type = request["Path"]},
    apiCall[request, type]
]

apiCall[_, _] := "Undefined API pattern"

apiCall[request_, "/api/"] := {
    "/api/ready/",
    "/api/notebook/",
    "/api/kernel/",
    "/api/alphaRequest/",
    "/api/promise/"
}

$promises = <||>;

apiCall[request_, "/api/promise/"] := With[{id = request["Body"]["Promise"]},
    If[MissingQ[$promises[id] ], failure["Missing promise or already resolved"],
        If[TrueQ[$promises[id]["ReadyQ"] ] ,
            With[{res = $promises[id]},
                $promises[id] = .;
                res
            ]
        ,
            $promises[id]
        ]
    ]
]

wolframAlphaRequest[query_String] := With[{str = ImportString[ExportString[
 WolframAlpha[query, "ShortAnswer"], 
  "Table",   CharacterEncoding -> "ASCII"
 ],  "String"]},
  If[!StringQ[str], failure["Failed request"],
    If[StringLength[str] > 1000, 
      StringTake[str, Min[StringLength[str], 1000] ]<>"..."
    ,
      str
    ]
  ]
];

apiCall[request_, "/api/alphaRequest/"] := With[{query = request["Body"]["Query"]},
    wolframAlphaRequest[query]
]

apiCall[request_, "/api/ready/"] := <|"ReadyQ" -> True|>


apiCall[request_, "/api/notebook/"] := {
    "/api/notebook/list/",
    "/api/notebook/create/",
    "/api/notebook/cells/"
}

apiCall[request_, "/api/notebook/list/"] := With[{},
    <|
        "Id"-> #["Hash"],
        "Opened" -> #["Opened"],
        "Path" -> #["Path"]
    |> &/@ Select[Values[nb`HashMap], (Complement[{"Opened", "Path", "Hash"}, #["Properties"] ] === {}) &]
]

$pullQue = {};
$stack[_] := False;
$activeSocket = Null;
$activeControls = Null;



EventHandler[EventClone[AppExtensions`AppEvents], {
    "Loader:NewNotebook" -> Function[notebook,
        If[Length[$pullQue] > 0, 
            $pullQue[[1]][ notebook["Hash"] ];
            $pullQue = Drop[$pullQue, 1]
        ];
    ],
    (* WARNING: this requires WLJS >= 2.8.4*)
    "AfterUILoad" -> Function[payload,
        $activeSocket = payload["Client"];
        $activeControls = payload["Controls"];
    ]
}]

apiCall[request_, "/api/notebook/create/"] := Module[{},
    If[$activeControls === Null, Return[failure["All windows are closed"], Module] ];
    With[{},
        With[{uid = CreateUUID[], promise = Promise[]},
            (*fixme*)
            $pullQue = Append[$pullQue, Function[n, 
                EventFire[promise, Resolve, n];
            ] ];

            Block[{Global`$Client = $activeSocket},
                EventFire[$activeControls, "_NewQuickNotebook", True];
                promise
            ]
        ]        
    ]
]



apiCall[request_, "/api/notebook/cells/"] := {
    "/api/notebook/cells/list/",
    "/api/notebook/cells/getlines/",
    "/api/notebook/cells/setlines/",
    "/api/notebook/cells/focused/",
    "/api/notebook/cells/add/",
    "/api/notebook/cells/add/markdown/",
    "/api/notebook/cells/add/js/",
    "/api/notebook/cells/add/html/",
    "/api/notebook/cells/evaluate/",
    "/api/notebook/cells/project/",
    "/api/notebook/cells/delete/"
}


apiCall[request_, "/api/notebook/cells/list/"] := Module[{body = request["Body"]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];
        With[{cells = notebook["Cells"]},
            <|
                "Id"-> #["Hash"],
                "Type" -> #["Type"],
                "Display" -> #["Display"],
                "Lines" -> StringCount[#["Data"], "\n"],
                "FirstLine" -> If[TrueQ[#["Overflow"] ], "[TOO LONG TO BE RENDERED]", StringExtract[#["Data"], "\n"->1] ]
            |> &/@ cells    
        ]
    ]
]




apiCall[request_, "/api/notebook/cells/focused/"] := Module[{body = request["Body"]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];
        With[{cell = notebook["FocusedCell"], ranges = notebook["FocusedCellSelection"]},
            If[MatchQ[cell, _cell`CellObj], <|
                "Id"-> cell["Hash"],
                "Display" -> cell["Display"],
                "Lines" -> StringCount[cell["Data"], "\n"],
                "FirstLine" -> StringExtract[cell["Data"], "\n"->1],
                "Selection" -> If[ListQ[ranges], ranges, Null]
            |>,
                failure["Nothing is focused"]
            ]
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/getlines/"] := Module[{body = request["Body"]},
    With[
        {
            cell = cell`HashMap[ body["Cell"] ],
            from = body["From"],
            to = body["To"]
        },
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell not found"], Module] ];
        If[!NumberQ[from] || !NumberQ[to], Return[failure["From or To is not a number"], Module] ];
        StringJoin[StringSplit[cell["Data"], "\n"][[from ;; to]], "\n"]
    ]
]

apiCall[request_, "/api/notebook/cells/setlines/"] := Module[{body = request["Body"]},
    With[
        {
            cell = cell`HashMap[ body["Cell"] ],
            from = body["From"],
            to = body["To"],
            content = body["Content"]
        },
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell not found"], Module] ];
        If[!NumberQ[from] || !NumberQ[to], Return[failure["From or To is not a number"], Module] ];
        If[cell["Type"] === "Output", Return[failure["Cannot edit output cells"], Module] ];

        
        With[{lines = StringSplit[cell["Data"], "\n"] }, Module[{
            before = If[from-1 > 0, Take[lines, from-1], {}],
            after = Drop[lines, to]
        },

            StringJoin[Flatten[{before, content, after}], "\n"]   
        ] ]
    ]
]

apiCall[request_, "/api/notebook/cells/delete/"] := Module[{body = request["Body"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[cell["Type"] === "Output", Return[failure["Cannot delete output cell. Delete parent input cell"], Module] ];
        Delete[cell];
        "Removed"
    ]
]


apiCall[request_, "/api/notebook/cells/add/"] := Module[{body = request["Body"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{
            after = cell`HashMap[ body["After"] ], 
            before = cell`HashMap[ body["Before"] ],
            display = Lookup[body, "Display", "codemirror"],
            type = Lookup[body, "Type", "Input"],
            hidden = Lookup[body, "Hidden", False]
        },
            If[!MatchQ[after, _cell`CellObj], 
                If[!MatchQ[before, _cell`CellObj],
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->body["Data"], "Hash"->uuid ]},
                        uuid
                    ]                
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->body["Data"], "Hash"->uuid, "Before"->before]},
                        uuid
                    ] 
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->body["Data"], "Hash"->uuid, "After"->after]},
                    uuid
                ] 
            ]
        ]

    ]
]

(* create directly an output cell with the content *)
apiCall[request_, "/api/notebook/cells/add/markdown/"] := Module[{body = request["Body"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ], before = cell`HashMap[ body["Before"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                If[!MatchQ[before, _cell`CellObj],
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Data"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"markdown" ];
                        new["Hash"]
                    ]                 
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Data"] ], "Before"->before, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"markdown"];
                        new["Hash"]
                    ]                
                ]                                       
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Data"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"markdown"];
                    new["Hash"]
                ]             
            ]
        ]

    ]
]

(* create directly an output cell with the content *)
apiCall[request_, "/api/notebook/cells/add/js/"] := Module[{body = request["Body"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ], before = cell`HashMap[ body["Before"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                If[!MatchQ[before, _cell`CellObj], 
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Data"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"js" ];
                        new["Hash"]
                    ]
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Data"] ], "Before"->before, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"js" ];
                        new["Hash"]
                    ]
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Data"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"js"];
                    new["Hash"]
                ]             
            ]
        ]

    ]
]

(* create directly an output cell with the content *)
apiCall[request_, "/api/notebook/cells/add/html/"] := Module[{body = request["Body"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ], before = cell`HashMap[ body["Before"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                If[!MatchQ[before, _cell`CellObj], 
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Data"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"html" ];
                        new["Hash"]
                    ]
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Data"] ], "Before"->before, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"html"];
                        new["Hash"]
                    ]
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Data"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"html"];
                    new["Hash"]
                ]             
            ]
        ]

    ]
]

apiCall[request_, "/api/notebook/cells/evaluate/"] := Module[{body = request["Body"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        {notebook = cell["Notebook"]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[TrueQ[notebook["Opened"] ], 
            With[{controller = notebook["Controller"], socket = notebook["Socket"], promise = Promise[]},
                (*fixme*)
                Block[{Global`$Client = socket},
  
                    Then[EventFire[controller, "NotebookCellEvaluateTemporal", cell], Function[Null,
                        With[{
                            out = Select[cell`SelectCells[notebook["Cells"], Sequence[cell, __?cell`OutputCellQ] ], cell`OutputCellQ]
                        },
                            EventFire[promise, Resolve, Map[Function[c, c["Hash"] ], out] ];
                        ]
                    ] ];
                    promise
                ]
            ]
        ,
            (* Can't evaluate cell in a closed notebook *)
            failure["Can't evaluate cell in a closed notebook. Use /api/kernel/evaluate/ path"]
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/project/"] := Module[{body = request["Body"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        {notebook = cell["Notebook"]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[TrueQ[notebook["Opened"] ], 
            With[{controller = notebook["Controller"], socket = notebook["Socket"]},
                (*fixme*)
                Block[{Global`$Client = socket},
                    EventFire[controller, "NotebookCellProject", cell];
                    "Window was created"
                ]
            ]
        ,
            (* Can't evaluate cell in a closed notebook *)
            failure["Can't evaluate cell in a closed notebook"]
        ]
    ]
]


apiCall[request_, "/api/kernel/"] := {
    "/api/kernel/evaluate/"
}

apiCall[request_, "/api/kernel/evaluate/"] := Module[{body = request["Body"]},
    With[
        {k = If[StringQ[body["Kernel"] ], 
            SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Kernel"]) &],  
            SelectFirst[AppExtensions`KernelList, (TrueQ[#["ContainerReadyQ"] ] && TrueQ[#["ReadyQ"] ]) &]
        ],
            expr = body["Expression"],
            promise = Promise[]
        },

        If[MissingQ[k], Return[failure["No kernel is ready for evaluation"], Module] ];

        GenericKernel`Async[k, 
            EventFire[Internal`Kernel`Stdout[ promise // First ], Resolve, ToString[ToExpression[expr, InputForm], InputForm] ];
        ];

        promise
    ]
]


existsOrEmpty[settings_, field_] := If[KeyExistsQ[settings, field], settings[field], {}]

existsOrTrue[settings_, field_] := If[KeyExistsQ[settings, field], settings[field], True]

With[{http = AppExtensions`HTTPHandler},
    http["MessageHandler", "ExternalAPI"] = AssocMatchQ[<|"Path" -> ("/api/"~~___)|>] -> HTTPAPICall;
];

End[]
EndPackage[]

