BeginPackage["CoffeeLiqueur`Extensions`API`", {
    "JerryI`Misc`Async`",
    "JerryI`Misc`Events`",
    "CoffeeLiqueur`Notebook`Transactions`",
    "JerryI`Misc`Events`Promise`",
    "JerryI`Misc`WLJS`Transport`",
    "JerryI`WLX`Importer`",
    "KirillBelov`HTTPHandler`",
    "KirillBelov`HTTPHandler`Extensions`",
    "KirillBelov`Internal`",
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


apiCall[request_] := With[{type = request["Path"]},
    Echo["API Request >> "<>type];
    Echo["Hi Alan x3"];
    Echo["API Request Body >> "<>(request["Body"] // ByteArrayToString)];
    With[{raw = apiCall[request, type]},
      If[MatchQ[raw, _failure],
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
      ]
    ]
]

apiCall[_, _] := "Undefined API pattern"

apiCall[request_, "/api/"] := {
    "/api/kernels/",
    "/api/transactions/",
    "/api/frontendobjects/",
    "/api/extensions/",
    "/api/ready/",
    "/api/notebook/",
    "/api/alphaRequest/"
}

apiCall[request_, "/api/alphaRequest/"] := With[{query = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]["Query"]},
    ImportString[ExportString[
        WolframAlpha[query, "ShortAnswer"], 
        "Table",   CharacterEncoding -> "ASCII"
    ],  "String"]
]

apiCall[request_, "/api/ready/"] := <|"ReadyQ" -> True|>


apiCall[request_, "/api/notebook/"] := {
    "/api/notebook/list/",
    "/api/notebook/create/",
    "/api/notebook/create/pull/",
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
        With[{uid = CreateUUID[]},
            (*fixme*)
            $pullQue = Append[$pullQue, Function[n, 
                $stack[uid] = n;
            ] ];

            Block[{Global`$Client = $activeSocket},
                EventFire[$activeControls, "_NewQuickNotebook", True];
                uid
            ]
        ]        
    ]
]

apiCall[request_, "/api/notebook/create/pull/"] := With[{uid = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]["Id"]},
    $stack[uid]
]



apiCall[request_, "/api/notebook/cells/"] := {
    "/api/notebook/cells/list/",
    "/api/notebook/cells/get/",
    "/api/notebook/cells/focused/",
    "/api/notebook/cells/set/",
    "/api/notebook/cells/add/",
    "/api/notebook/cells/add/markdown/",
    "/api/notebook/cells/add/js/",
    "/api/notebook/cells/add/html/",
    "/api/notebook/cells/evaluate/",
    "/api/notebook/cells/project/",
    "/api/notebook/cells/delete/"
}


apiCall[request_, "/api/notebook/cells/list/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];
        With[{cells = notebook["Cells"]},
            <|
                "Id"-> #["Hash"],
                "Type" -> #["Type"],
                "State" -> #["State"],
                "Display" -> #["Display"]
            |> &/@ cells    
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/list/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];
        With[{cells = notebook["Cells"]},
            <|
                "Id"-> #["Hash"],
                "Type" -> #["Type"],
                "State" -> #["State"],
                "Display" -> #["Display"]
            |> &/@ cells    
        ]
    ]
]




apiCall[request_, "/api/notebook/cells/focused/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];
        With[{cell = notebook["FocusedCell"]},
            <|
                "Id"-> #["Hash"],
                "Type" -> #["Type"],
                "State" -> #["State"],
                "Display" -> #["Display"]
            |> & @ If[MatchQ[cell, _cell`CellObj], cell, notebook["Cells"] // Last]
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/get/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        cell["Data"]
    ]
]

apiCall[request_, "/api/notebook/cells/delete/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        Delete[cell];
        "Removed"
    ]
]

apiCall[request_, "/api/notebook/cells/set/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[!cell`OutputQ[cell], Return[failure["Cannot edit output cells"], Module] ];
        
        If[TrueQ[cell["Notebook"]["Opened"] ], 
            EventFire[cell, "ChangeContent", body["Data"] ];
            "Data field was updated live in the notebook"
        ,
            cell["Data"] = body["Data"];
            "Data field was updated"
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/add/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->body["Data"], "Hash"->uuid ]},
                    "Added to the end of the notebook"
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->body["Data"], "Hash"->uuid, "After"->after]},
                    "Added after "<>after["Hash"]
                ]
            ]
        ]

    ]
]

(* create directly an output cell with the content *)
apiCall[request_, "/api/notebook/cells/add/markdown/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Data"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"markdown" ];
                    "Added to the end of the notebook"
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".md\n", body["Data"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"markdown"];
                    "Added after "<>after["Hash"]
                ]             
            ]
        ]

    ]
]

(* create directly an output cell with the content *)
apiCall[request_, "/api/notebook/cells/add/js/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Data"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"js" ];
                    "Added to the end of the notebook"
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".js\n", body["Data"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"js"];
                    "Added after "<>after["Hash"]
                ]             
            ]
        ]

    ]
]

(* create directly an output cell with the content *)
apiCall[request_, "/api/notebook/cells/add/html/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"], uuid = CreateUUID[]},
    With[
        {notebook = nb`HashMap[ body["Notebook"] ]},
        If[!MatchQ[notebook, _nb`NotebookObj], Return[failure["Notebook is missing"], Module] ];

        If[MatchQ[body["Id"], _String], uuid = body["Id"] ];

        With[{after = cell`HashMap[ body["After"] ]},
            If[!MatchQ[after, _cell`CellObj], 
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Data"] ], "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"html" ];
                    "Added to the end of the notebook"
                ]                                        
            ,
                With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->StringJoin[".html\n", body["Data"] ], "After"->after, "Props"-><|"Hidden"->True|>, "Hash"->uuid ]},
                    cell`CellObj["Notebook"->notebook, "After"->new, "Type"->"Output", "Data"->body["Data"], "Display"->"html"];
                    "Added after "<>after["Hash"]
                ]             
            ]
        ]

    ]
]

(* Note: a user has to choose manually a kernel for the first time *)
apiCall[request_, "/api/notebook/cells/evaluate/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        {notebook = cell["Notebook"]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[TrueQ[notebook["Opened"] ], 
            With[{controller = notebook["Controller"], socket = notebook["Socket"]},
                (*fixme*)
                Block[{Global`$Client = socket},
                    EventFire[controller, "NotebookCellEvaluate", cell];
                    "Submitted"
                ]
            ]
        ,
            (* Can't evaluate cell in a closed notebook *)
            failure["Can't evaluate cell in a closed notebook. Use transactions"]
        ]
    ]
]

apiCall[request_, "/api/notebook/cells/project/"] := Module[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[
        {cell = cell`HashMap[ body["Cell"] ]},
        {notebook = cell["Notebook"]},
        If[!MatchQ[cell, _cell`CellObj], Return[failure["Cell is missing"], Module] ];
        If[TrueQ[notebook["Opened"] ], 
            With[{controller = notebook["Controller"], socket = notebook["Socket"]},
                (*fixme*)
                Block[{Global`$Client = socket},
                    EventFire[controller, "NotebookCellProject", cell];
                    "Evaluation started"
                ]
            ]
        ,
            (* Can't evaluate cell in a closed notebook *)
            failure["Can't evaluate cell in a closed notebook"]
        ]
    ]
]





apiCall[request_, "/api/frontendobjects/"] := {
    "/api/frontendobjects/get/"
}


objects = <||>;

apiCall[request_, "/api/frontendobjects/get/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{
        k = If[StringQ[body["Kernel"] ], 
            SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Kernel"]) &],  
            SelectFirst[AppExtensions`KernelList, (TrueQ[#["ContainerReadyQ"] ] && TrueQ[#["ReadyQ"] ]) &]
        ],
        uid = body["UId"],
        promise = Promise[]
    },
        Echo["Fetching object: "<>uid];

        If[!KeyExistsQ[objects, uid],
            Echo["not found, requesting: "<>uid];

            If[MissingQ[k], failure["Kernel is missing"], 

                With[{
                    promiseId = promise // First
                },
                    GenericKernel`Async[k, With[{o = CoffeeLiqueur`Extensions`FrontendObject`Internal`GetObject[uid]},
                            EventFire[Internal`Kernel`Stdout[promiseId], Resolve, ExportByteArray[o, "ExpressionJSON", "Compact"->1] ];
                        ]
                    ];
                ];

                objects[uid] = <|"Resolved" -> False|>;

                Then[promise, Function[data,
                    Echo["Resolved for: "<>uid];
                    Echo[data // ByteArrayToString];
                    objects[uid] = Join[objects[uid], <|"Resolved" -> True,
                                                        "Data" -> ByteArrayToString[data]|>
                    ];
                ] ];

                objects[uid]

            ]
        ,
            With[{o = objects[uid]},
                If[o["Resolved"] === True,
                    objects[uid] = .;
                    o
                ]
            ]
            
        ]
    ]    
]


apiCall[request_, "/api/transactions/"] := {
    "/api/transactions/create/",
    "/api/transactions/get/",
    "/api/transactions/delete/",
    "/api/transactions/list/"
}

transactions = {};

apiCall[request_, "/api/transactions/create/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{
        k = SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Kernel"]) &]
    },
        If[MissingQ[k], failure["Kernel is missing"], 
            submitTransaction[body["Data"], k]
        ]
    ]
]

apiCall[request_, "/api/transactions/delete/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{
        m = SelectFirst[transactions, (#["Hash"] === body["Hash"]) &]
    },
        If[MissingQ[m], failure["Transaction is missing"],
            transactions = transactions /. {m -> Nothing};
            True
        ]
    ]
]

apiCall[request_, "/api/transactions/get/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{
        m = SelectFirst[transactions, (#["Hash"] === body["Hash"]) &]
    },
        If[MissingQ[m], failure["Transaction is missing"],
            <|
                "Hash" -> #["Hash"],
                "State" -> If[StringQ[#["State"] ], #["State"], "Undefined" ],
                "Result" -> If[ListQ[#["Result"] ], #["Result"], {} ]
            |>&@m
        ]
    ]
]

apiCall[request_, "/api/transactions/list/"] := With[{},
    With[{
        
    },
            <|
                "Hash" -> #["Hash"],
                "State" -> If[StringQ[#["State"] ], #["State"], "Undefined" ]
            |>& /@ transactions
    ]
]

submitTransaction[input_String, kernel_] := With[{transaction = Transaction[]},
   transactions = Append[transactions, transaction];
   transaction["Data"] = input;
   transaction["State"] = "Evaluation";
   transaction["Result"] = {};   
   transaction["EvaluationContext"] = <||>;

   EventHandler[transaction, {"Result" -> Function[data,
       (* AFTER, BEFORE, TYPE, PROPS can be altered using provided meta-data from the transaction *)

       If[data["Data"] != "Null",
           If[KeyExistsQ[data, "Meta"],
               transaction["Result"] = Append[transaction["Result"], <|"Data"->data["Data"], data["Meta"], "Type"->"Output"(*"" data["Meta"]*)|> ]
               
           ,
               transaction["Result"] = Append[transaction["Result"], <|"Data"->data["Data"], "Display"->"codemirror", "Type"->"Output"(*"" data["Meta"]*)|> ]
               
           ]
       ];
   ],
       "Finished" -> Function[Null,
           transaction["State"] = "Idle";
           Echo["Finished!"];
       ],

       "Error" -> Function[error,
           transaction["State"] = "Error";
           Echo["Error in evalaution... check syntax"];
       ]
   }];

   (* submit *)
   kernel["Container"][transaction];   
   transaction["Hash"]
]



apiCall[request_, "/api/kernels/"] := {
    "/api/kernels/list/",
    "/api/kernels/restart/",
    "/api/kernels/abort/",
    "/api/kernels/get/",
    "/api/kernels/create/",
    "/api/kernels/unlink/",
    "/api/kernels/init/",
    "/api/kernels/deinit/",
    "/api/kernels/fetch/"
}

requests = <||>;


fetchRequest[sym_, args_, kernel_] := With[{
   arguments = args,
   symbol = sym,
   promise = Promise[]
},
   With[{key = promise // First}, 
    requests[key] = <|"ReadyQ"->False|>;
    Then[promise, Function[value, 
        requests[key] = <|"Result"->ByteArrayToString[value], "ReadyQ"->True|>;
    ] ];

    Echo["Fetch symbol: "<>ToString[sym, InputForm] ];
    Echo["with arguments: "<>ToString[args, InputForm] ];

    GenericKernel`Async[kernel, 
        With[{esymbol = ToExpression[symbol]},
            With[{result = (esymbol @@ arguments)},
                If[MatchQ[result, _Promise],
                    Then[result, Function[xa,
                        EventFire[Internal`Kernel`Stdout[ key ], Resolve, ExportByteArray[xa, "ExpressionJSON"] ] 
                    ] ]
                ,
                    EventFire[Internal`Kernel`Stdout[ key ], Resolve, ExportByteArray[result, "ExpressionJSON"] ] 
                ];
            ]
        ]
    ];
    
    key
   ]
]

apiCall[request_, "/api/kernels/fetch/get/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{
        uid = requests[ body["UId"] ]
    },
        If[MissingQ[uid], failure["UId is not provided or is missing"], 
            uid
        ]
    ]
]

apiCall[request_, "/api/kernels/fetch/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{
        k = If[StringQ[body["Kernel"] ], 
            SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Kernel"]) &],
            SelectFirst[AppExtensions`KernelList, (TrueQ[#["ContainerReadyQ"] ] && TrueQ[#["ReadyQ"] ]) &]
        ]
    },
        If[MissingQ[k], failure["Kernel is missing or not ready"], 
            fetchRequest[body["Symbol"], body["Args"], k]
        ]
    ]
]

apiCall[request_, "/api/kernels/list/"] := With[{},
    <|
        "Hash"->#["Hash"], 
        "State"->#["State"], 
        "ReadyQ"->#["ReadyQ"], 
        "Name"->#["Name"],
        "ContainerReadyQ" -> TrueQ[#["ContainerReadyQ"] ]
    |> &/@ AppExtensions`KernelList
];

apiCall[request_, "/api/kernels/get/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{m = SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Hash"]) &]},
        If[MissingQ[m], failure["Kernel is missing"],
            <|
                "Hash"->#["Hash"], 
                "State"->#["State"], 
                "ReadyQ"->#["ReadyQ"], 
                "Name"->#["Name"],
                "ContainerReadyQ" -> TrueQ[#["ContainerReadyQ"] ]
            |> & @ m
        ]
    ]
];

apiCall[request_, "/api/kernels/restart/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{m = SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Hash"]) &]},
        If[MissingQ[m], failure["Kernel is missing"],
            GenericKernel`Restart[m];
            True
        ]
    ]
];

apiCall[request_, "/api/kernels/create/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    failure@"Not implemented"
];

apiCall[request_, "/api/kernels/unlink/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    failure@"Not implemented"
];

apiCall[request_, "/api/kernels/abort/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{m = SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Hash"]) &]},
        If[MissingQ[m], failure["Kernel is missing"],
            GenericKernel`AbortEvaluation[m];
            True
        ]
    ]
];

apiCall[request_, "/api/kernels/init/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{m = SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Hash"]) &]},
        If[MissingQ[m], failure["Kernel is missing"],
            initKernel[<|"env" -> $Env|>][m];
            True
        ]
    ]
];

apiCall[request_, "/api/kernels/deinit/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    With[{m = SelectFirst[AppExtensions`KernelList, (#["Hash"] === body["Hash"]) &]},
        If[MissingQ[m], failure["Kernel is missing"],
            deinitKernel[m];
            True
        ]
    ]
];

{deinitKernel, initKernel}           = ImportComponent["Frontend/KernelUtils.wl"];

apiCall[request_, "/api/cdn/"] := {
    "/api/cdn/list/",
    "/api/cdn/get/js/",
    "/api/cdn/get/styles/"
}

apiCall[request_, "/api/cdn/get/js/"] := With[{
    body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"],
    thisrepo = WLJSPackages`Packages["wljs-api", "key"]
},
    Join[{
        "https://cdn.skypack.dev/twind/shim"
    }, getCDNJS[Flatten[{body}] /. {"common-css" -> Nothing}], {
        StringJoin[StringTemplate["https://cdn.jsdelivr.net/gh/``@``/"][getRepo[thisrepo ], getBranch[thisrepo ] ], "assets/polyfill.js" ]
    }]
]

apiCall[request_, "/api/cdn/get/styles/"] := With[{
    thisrepo = WLJSPackages`Packages["wljs-api", "key"]
},
    {
        StringJoin[StringTemplate["https://cdn.jsdelivr.net/gh/``@``/"][getRepo[thisrepo ], getBranch[thisrepo ] ], "assets/minimal.css" ]
    }
]

apiCall[request_, "/api/cdn/list/"] := With[{},
    Join[Map[Function[key, 
        key
    ], 
        Select[WLJSPackages`Packages // Keys, (WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], "minjs"]) &] 
    ] ]
]


getCDNJS[list_] := With[{}, 
  (With[{
    url = StringJoin[StringTemplate["https://cdn.jsdelivr.net/gh/``@``/"][getRepo[#["key"] ], getBranch[#["key"] ] ], #["path"] ]
  },

    url

  ]& /@ Flatten[Table[
      Table[
          <|"key"->WLJSPackages`Packages[i, "key"], "path"->j|>
      , {j, {WLJSPackages`Packages[i, "wljs-meta", "js"]} // Flatten}]
  , {i, list} ] ]) 
]

existsOrEmpty[settings_, field_] := If[KeyExistsQ[settings, field], settings[field], {}]

existsOrTrue[settings_, field_] := If[KeyExistsQ[settings, field], settings[field], True]


getRepo[Rule[_, url_String]] := StringReplace[url, "https://github.com/"~~s_:>s]
getBranch[Rule[_, url_String]] := "master"

getRepo[Rule[_, Rule[url_String, _]]] := StringReplace[url, "https://github.com/"~~s_:>s]
getBranch[Rule[_, Rule[url_String, branch_String]]] := branch


apiCall[request_, "/api/extensions/"] := {
    "/api/extensions/list/",
    "/api/extensions/get/minjs/",
    "/api/extensions/bundle/minjs/",
    "/api/extensions/get/styles/",
    "/api/extensions/bundle/styles/"
}

apiCall[request_, "/api/extensions/list/"] := With[{},
    Join[Map[Function[key, 
        <|"name" -> key, "version" -> WLJSPackages`Packages[key, "version"]|>
    ], 
        Select[WLJSPackages`Packages // Keys, (WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], "minjs"]) &] 
    ], {<|"name" -> "common-css", "version" -> "0.1"|>}]
]

pmIncludes[param_, whitelist_List] := 
Table[ 
    Table[ 
      Import[FileNameJoin[{WLJSPackages`Packages[i, "name"], StringSplit[j, "/"]} // Flatten], "Text", Path->{FileNameJoin[{Directory[], "wljs_packages"}], AppExtensions`ExtensionsDir}] // URLEncode
    , {j, {WLJSPackages`Packages[i, "wljs-meta", param]} // Flatten} ]
, {i, Select[WLJSPackages`Packages // Keys, (MemberQ[whitelist, #] && WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], param])&]}] // Flatten;

pmIncludesNoEncode[param_, whitelist_List] := 
Table[ 
    Table[ 
      Import[FileNameJoin[{WLJSPackages`Packages[i, "name"], StringSplit[j, "/"]} // Flatten], "Text", Path->{FileNameJoin[{Directory[], "wljs_packages"}], AppExtensions`ExtensionsDir}] 
    , {j, {WLJSPackages`Packages[i, "wljs-meta", param]} // Flatten} ]
, {i, Select[WLJSPackages`Packages // Keys, (MemberQ[whitelist, #] && WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], param])&]}] // Flatten;

pmIncludesNoEncode[param_, alterparam_, whitelist_List] := 
Table[ 
    Table[ 
      Import[FileNameJoin[{WLJSPackages`Packages[i, "name"], StringSplit[j, "/"]} // Flatten], "Text", Path->{FileNameJoin[{Directory[], "wljs_packages"}], AppExtensions`ExtensionsDir}] 
    , {j, {WLJSPackages`Packages[i, "wljs-meta", alterparam]} // Flatten} ]
, {i, Select[WLJSPackages`Packages // Keys, (MemberQ[whitelist, #] && WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], param])&]}] // Flatten;


apiCall[request_, "/api/extensions/get/minjs/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    pmIncludes["minjs", Flatten[{body}] /. {"common-css" -> Nothing} ]
]

inBlackList[key_] := MemberQ[{"wljs-markdown-support", "wljs-plotly", "wljs-wxf-accelerator", "wljs-html-support", "wljs-js-support", "wljs-sharedlib-mk", "wljs-mermaid-support", "wljs-revealjs"}, key]

globalWindow = ""

apiCall[request_, "/api/extensions/bundle/minjs/"] := With[{list = Select[WLJSPackages`Packages // Keys, (WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], "minjs"] && !inBlackList[#]) &] },
    StringJoin[globalWindow, "/* wljs-api bundler */\r\n{\r\n", StringRiffle[pmIncludesNoEncode["minjs", Flatten[{list}] ], "\r\n}\r\n{\r\n"], "\r\n}"] // URLEncode
]

common = Import[FileNameJoin[{$InputFileName // DirectoryName // ParentDirectory, "assets", "common.css"}], "Text"];

apiCall[request_, "/api/extensions/get/styles/"] := With[{body = ImportByteArray[request["Body"], "RawJSON", CharacterEncoding -> "UTF-8"]},
    If[MemberQ[ Flatten[{body}], "common-css"], 
        Join[pmIncludes["styles", Flatten[{body}] ], {
            common // URLEncode
        }]
    ,
        pmIncludes["styles", Flatten[{body}] ]
    ]
]

apiCall[request_, "/api/extensions/bundle/styles/"] := With[{list = Select[WLJSPackages`Packages // Keys, (WLJSPackages`Packages[#, "enabled"] && KeyExistsQ[WLJSPackages`Packages[#, "wljs-meta"], "minjs"]) &]},
    StringRiffle[Join[pmIncludesNoEncode["styles", Flatten[{list}] ], {common}], "\r\n\r\n"] // URLEncode
]




With[{http = AppExtensions`HTTPHandler},
    http["MessageHandler", "ExternalAPI"] = AssocMatchQ[<|"Path" -> ("/api/"~~___)|>] -> apiCall;
];

End[]
EndPackage[]

