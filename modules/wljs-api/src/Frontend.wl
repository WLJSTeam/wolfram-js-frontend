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
    "/api/notebook/cells/setlines/batch/",
    "/api/notebook/cells/insertlines/",
    "/api/notebook/cells/focused/",
    "/api/notebook/cells/add/",
    "/api/notebook/cells/add/batch/",
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
                "Lines" -> StringCount[#["Data"], "\n"]+1,
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
            If[MatchQ[cell, _cell`CellObj], With[{data = cell["Data"]}, <|
                "Id"-> cell["Hash"],
                "Display" -> cell["Display"],
                "Lines" -> StringCount[data, "\n"]+1,
                "FirstLine" -> StringExtract[data, "\n"->1],
                "SelectedLines" -> If[ListQ[ranges], 
                    {
                        StringCount[StringTake[data, Min[ranges[[1]], StringLength[data] ] ], "\n"] + 1,
                        StringCount[StringTake[data, Min[ranges[[2]], StringLength[data] ] ], "\n"] + 1
                    },
                    Null
                ]
            |>],
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
        StringRiffle[StringSplit[cell["Data"], "\n"][[from ;; to]], "\n"]
    ]
]

updateCellContent[cell_, newData_] :=  If[TrueQ[cell["Notebook"]["Opened"] ],
                EventFire[cell, "ChangeContent", newData ];
            ,
                cell["Data"] = newData;
            ];

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

        
        With[{lines = StringSplit[cell["Data"], "\n"] }, With[{
            before = If[from-1 > 0, Take[lines, from-1], {}],
            after = If[to==Length[lines], {}, Drop[lines, to] ]
        },
        {
            newData = StringRiffle[Flatten[{before, content, after}], "\n"]   
        },

            updateCellContent[cell, newData];
            
            "Lines were set"
        ] ]
    ]
]

(* Insert lines after a specific line number *)
(* After: 0 means insert at the beginning, After: n means insert after line n *)
apiCall[request_, "/api/notebook/cells/insertlines/"] := Module[{body = request["Body"]},
    With[
        {
            cell = cell`HashMap[ body["Cell"] ],
            after = body["After"],
            content = body["Content"]
        },
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell not found"], Module] ];
        If[!NumberQ[after], Return[failure["After must be a number"], Module] ];
        If[!StringQ[content], Return[failure["Content must be a string"], Module] ];
        If[cell["Type"] === "Output", Return[failure["Cannot edit output cells"], Module] ];

        With[{lines = StringSplit[cell["Data"], "\n", All]},
            With[{
                before = If[after > 0, Take[lines, Min[after, Length[lines]]], {}],
                afterLines = If[after >= Length[lines], {}, Drop[lines, after]]
            },
            With[{
                newData = StringRiffle[Flatten[{before, content, afterLines}], "\n"]
            },
                updateCellContent[cell, newData];
                "Lines were inserted"
            ] ]
        ]
    ]
]

(* Batch setlines: apply multiple non-overlapping line changes in a single call *)
(* Changes format: [{"From": n, "To": m, "Content": "..."}, ...] *)
(* Changes are applied from bottom to top to preserve line indices *)
apiCall[request_, "/api/notebook/cells/setlines/batch/"] := Module[{body = request["Body"]},
    With[
        {
            cell = cell`HashMap[ body["Cell"] ],
            changes = body["Changes"]
        },
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell not found"], Module] ];
        If[!ListQ[changes], Return[failure["Changes must be a list"], Module] ];
        If[cell["Type"] === "Output", Return[failure["Cannot edit output cells"], Module] ];
        If[Length[changes] === 0, Return["No changes to apply", Module] ];
        
        (* Validate all changes have required fields *)
        If[!AllTrue[changes, (NumberQ[#["From"]] && NumberQ[#["To"]] && StringQ[#["Content"]]) &],
            Return[failure["Each change must have numeric From, To and string Content"], Module]
        ];
        
        (* Sort changes by From line descending to apply from bottom to top *)
        With[{sortedChanges = SortBy[changes, -#["From"] &]},
            (* Check for overlapping ranges *)
            If[Length[sortedChanges] > 1 && !AllTrue[Partition[sortedChanges, 2, 1], (#[[1]]["From"] > #[[2]]["To"]) &],
                Return[failure["Changes have overlapping line ranges"], Module]
            ];
            
            (* Apply changes from bottom to top *)
            With[{lines = StringSplit[cell["Data"], "\n", All]},
                With[{newLines = Fold[
                    Function[{currentLines, change},
                        With[{
                            from = change["From"],
                            to = change["To"],
                            content = change["Content"]
                        },
                            With[{
                                before = If[from - 1 > 0, Take[currentLines, from - 1], {}],
                                after = If[to >= Length[currentLines], {}, Drop[currentLines, to]]
                            },
                                Flatten[{before, content, after}]
                            ]
                        ]
                    ],
                    lines,
                    sortedChanges
                ]},
                    updateCellContent[cell, StringRiffle[newLines, "\n"]];
                    <|"Applied" -> Length[changes], "Message" -> "Batch lines were set"|>
                ]
            ]
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/delete/"] := Module[{body = request["Body"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[cell["Type"] === "Output", Return[failure["Cannot delete output cell. Delete parent input cell"], Module] ];
        Delete[cell];
        "Removed 1 cell"
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
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->body["Content"], "Hash"->uuid ]},
                        uuid
                    ]                
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->body["Content"], "Hash"->uuid, "Before"->before]},
                        uuid
                    ] 
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->body["Content"], "Hash"->uuid, "After"->after]},
                    uuid
                ] 
            ]
        ]

    ]
]

(* Batch add cells: insert multiple cells sequentially after an anchor cell *)
(* Cells format: [{"Content": "...", "Type": "Input", "Display": "codemirror"}, ...] *)
(* Returns array of created cell IDs in order *)
apiCall[request_, "/api/notebook/cells/add/batch/"] := Module[{body = request["Body"], createdIds = {}},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];
        
        With[{
            cells = body["Cells"],
            anchorAfter = cell`HashMap[ body["After"] ],
            anchorBefore = cell`HashMap[ body["Before"] ]
        },
            If[!ListQ[cells], Return[failure["Cells must be a list"], Module] ];
            If[Length[cells] === 0, Return[failure["Cells list is empty"], Module] ];
            
            (* Validate all cells have Content *)
            If[!AllTrue[cells, StringQ[#["Content"]] &],
                Return[failure["Each cell must have a string Content field"], Module]
            ];
            
            (* Determine starting anchor *)
            Module[{currentAnchor = Null, insertMode = "after"},
                If[MatchQ[anchorAfter, _cell`CellObj],
                    currentAnchor = anchorAfter;
                    insertMode = "after";
                ,
                    If[MatchQ[anchorBefore, _cell`CellObj],
                        currentAnchor = anchorBefore;
                        insertMode = "before";
                    ]
                ];
                
                (* Create cells sequentially *)
                Do[
                    With[{
                        cellData = cells[[i]],
                        uuid = If[StringQ[cells[[i]]["Id"]], cells[[i]]["Id"], CreateUUID[]]
                    },
                        With[{
                            display = Lookup[cellData, "Display", "codemirror"],
                            type = Lookup[cellData, "Type", "Input"],
                            hidden = Lookup[cellData, "Hidden", False]
                        },
                            If[currentAnchor === Null,
                                (* No anchor - append to notebook *)
                                With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->cellData["Content"], "Hash"->uuid]},
                                    AppendTo[createdIds, uuid];
                                    currentAnchor = new;
                                    insertMode = "after";
                                ]
                            ,
                                If[insertMode === "after",
                                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->cellData["Content"], "Hash"->uuid, "After"->currentAnchor]},
                                        AppendTo[createdIds, uuid];
                                        currentAnchor = new;
                                    ]
                                ,
                                    (* First cell goes before anchor, rest chain after it *)
                                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->type, "Display"->display, "Props"-><|"Hidden"->hidden|>, "Data"->cellData["Content"], "Hash"->uuid, "Before"->currentAnchor]},
                                        AppendTo[createdIds, uuid];
                                        currentAnchor = new;
                                        insertMode = "after"; (* subsequent cells go after the first *)
                                    ]
                                ]
                            ]
                        ]
                    ],
                    {i, Length[cells]}
                ];
                
                <|"Created" -> createdIds, "Count" -> Length[createdIds]|>
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
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Content"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"markdown" ];
                        new["Hash"]
                    ]                 
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Content"] ], "Before"->before, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"markdown"];
                        new["Hash"]
                    ]                
                ]                                       
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Content"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"markdown"];
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
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Content"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"js" ];
                        new["Hash"]
                    ]
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Content"] ], "Before"->before, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"js" ];
                        new["Hash"]
                    ]
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Content"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"js"];
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
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Content"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"html" ];
                        new["Hash"]
                    ]
                ,
                    With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Content"] ], "Before"->before, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                        cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"html"];
                        new["Hash"]
                    ]
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Content"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Content"], "Display"->"html"];
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
        If[cell["Type"] === "Output", Return[failure["Output cells cannot be projected"], Module] ];
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
            failure["Can't project cell in a closed notebook"]
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

