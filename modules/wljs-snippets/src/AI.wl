BeginPackage["CoffeeLiqueur`Extensions`CommandPalette`AI`", {
    "CoffeeLiqueur`Notebook`Transactions`",
    "CoffeeLiqueur`Misc`Events`",
    "CoffeeLiqueur`Misc`Async`",
    "CoffeeLiqueur`Misc`Events`Promise`",
    "CoffeeLiqueur`WLX`",
    "CoffeeLiqueur`WLX`WLJS`",
    "CoffeeLiqueur`Misc`WLJS`Transport`",
    "CoffeeLiqueur`WLX`Importer`",
    "CoffeeLiqueur`WLX`WebUI`",     
    "CoffeeLiqueur`Extensions`CommandPalette`",
    "CoffeeLiqueur`Extensions`EditorViewMinimal`",
    "CoffeeLiqueur`HTTPHandler`",
    "CoffeeLiqueur`HTTPHandler`Extensions`",
    "CoffeeLiqueur`Internal`",
    "CoffeeLiqueur`LPM`",
    "CoffeeLiqueur`Objects`"
}]

Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];
Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Needs["CoffeeLiqueur`GPTLink`", FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName] ], "packages", "GPTLink.wl"}] ];

Needs["CoffeeLiqueur`Extensions`CommandPalette`VFX`" -> "vfx`", FileNameJoin[{DirectoryName[$InputFileName], "VFX.wl"}] ];



GPTChatObject /: EventHandler[o_GPTChatObject, opts_] := EventHandler[o["Hash"], opts]
GPTChatObject /: EventFire[o_GPTChatObject, opts__] := EventFire[o["Hash"], opts]
GPTChatObject /: EventClone[o_GPTChatObject] := EventClone[o["Hash"] ]
GPTChatObject /: EventRemove[o_GPTChatObject, opts_] := EventRemove[o["Hash"], opts]


AIChatRenderer;
vfx`MagicWand;

AIChat`HashMap;

Begin["`Private`"]


CoffeeLiqueur`Extensions`CommandPalette`AI`Private`Siriwave;

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];
Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];

Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];


AIChat`HashMap = <||>;

$rootDir =  ParentDirectory[ DirectoryName[$InputFileName] ];

AIChatRenderer = "";

chatWindow = ImportComponent[FileNameJoin[{$rootDir, "template", "Chat.wlx"}] ];

{loadSettings, storeSettings}        = ImportComponent["Frontend/Settings.wl"];

settings = <||>;
loadSettings[settings];


settingsKeyTable = {
    "Endpoint" -> "AIAssistantEndpoint",
    "Model" -> "AIAssistantModel",
    "MaxTokens" -> "AIAssistantMaxTokens",
    "Temperature" -> "AIAssistantTemperature"
};

SimpleYAMLParser[yaml_String] := Module[{lines, parseLine, assoc, toValue},
  
  (* Split YAML content into lines *)
  lines = StringSplit[yaml, "\n"];
  
  (* Function to convert string to appropriate value *)
  toValue[value_String] := Which[
    value === "true", True,
    value === "false", False,
    True, value
  ];
  
  (* Function to parse a single line *)
  parseLine[line_String] := Module[{key, value},
    (* Split the line into key and value at the first colon *)
    {key, value} = StringTrim /@ StringSplit[line, ":", 2];
    key -> toValue[value]
  ];
  
  (* Build association from parsed lines *)
  assoc = Association@Map[parseLine, Select[lines, StringContainsQ[":"]]];
  
  assoc
]

ParseFrontMatter[content_String] := Module[{ frontMatter},
  
  
  (* Extract the front matter between the first and second `---` *)
  frontMatter = StringCases[content, 
    "---" ~~ ShortestMatch[fm__] ~~ "---" ~~ rest__ :> {fm, rest}, 1];
  
  (* If front matter exists, parse it into an association *)
  Join[If[frontMatter =!= {},
    SimpleYAMLParser[frontMatter[[1,1]]],
    <||> (* Return an empty association if no front matter is found *)
  ], <|"content" -> frontMatter[[1,2]]|>]
]

defaultSysPrompt = Compress[Import[FileNameJoin[{$rootDir, "rules.default.min.txt"}], "Text"] ];

getParameter[key_] := With[{
        params = Join[<|
            "AIAssistantEndpoint" -> "https://api.openai.com", 
            "AIAssistantModel" -> "gpt-4o", 
            "AIAssistantMaxTokens" -> 70000, 
            "AIAssistantTemperature" -> 0.3,
            "AIAssistantInitialPrompt" -> True,
            "AIAssistantLibraryStopList" -> {},
            "AIAssistantAutocomplit" -> False,
            "AIAssistantAssistantPrompt" -> defaultSysPrompt
        |>, settings],

        skey = key /. settingsKeyTable
    },

    params[skey]
]

library = <||>;
libraryTotalItems = 0;
With[{libItems = Table[Import[i, "Text"], {i, FileNames["*.txt", FileNameJoin[{$rootDir, "promts"}] ]}], stopList = getParameter["AIAssistantLibraryStopList"]},
    Map[
        (libraryTotalItems++;
        With[{hash = ToString[libraryTotalItems], content = ParseFrontMatter[#]},
            library[hash] = Join[<|
                "hash" -> hash,
                "words" -> ToString[WordCount[#] ],
                "enabled" -> (!MemberQ[stopList, content["title"] ])
            |>, content ];
        ])&    
    , libItems];
];


AppExtensions`TemplateInjection["SettingsFooter"] = (ImportComponent[FileNameJoin[{$rootDir, "template", "Settings.wlx"}] ][<|"Library" -> Hold[library], "DefaultAIAssistantAssistantPrompt" -> Uncompress[defaultSysPrompt]|>]);


With[{http = AppExtensions`HTTPHandler},
    Echo[http];
    http["MessageHandler", "ChatWindow"] = AssocMatchQ[<|"Path" -> "/gptchat"|>] -> chatWindow;
];

GPTChatCompletePromise[args__, rules___Rule] := With[{p = Promise[], o = {args} // First},
    Echo["MaxTokens: "<>ToString[o["MaxTokens"] ] ];
    Echo["TokensTotal: "<>ToString[o["TotalTokens"] ] ];


    GPTChatCompleteAsync[args, Function[data,
        With[{},
            EventFire[o, "Complete", o["Messages"] ];
        ];
        EventFire[p, Resolve, data];
    ], rules];
    p
];

Print[">> Snippets >> AI loading..."];

makePromt[data_Association] := data["Promt"]

getNotebook[assoc_Association] := With[{result = EventFire[assoc["Controls"], "NotebookQ", True] /. {{___, n_nb`NotebookObj, ___} :> n}},
    Print[result];
    Echo["Getting notebook"];
    If[MatchQ[result, _nb`NotebookObj],
            result
    ,
            Echo["rejected"];
            EventFire[assoc["Messanger"], "Warning", "There is no opened notebook" ];
            $Failed
    ]
]

removeQuotes[str_String] := If[StringTake[str, 1] === "\"", StringDrop[StringDrop[str, -1], 1], str ];

(* Routes for LLM *)
(*

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

    "/api/kernel/evaluate/"

    "/api/alphaRequest/"

*)

makeAPIRequest[path_String, body_, callback_] := With[{p = Promise[]},
    EventFire[AppExtensions`AppEvents, "WLJSAPI:ApplyFunctionRequest", Function[{requestGenerator, failureQ},
        Echo[StringTemplate["\nUsing API: `` with ``\n"][path, body] ];

        With[{result = requestGenerator[<|"Body"->body|>, path]},
            If[PromiseQ[result],
                Then[result, Function[promised,
                    Echo[StringTemplate["\nUsing API: `` result: ``\n"][path, promised] ];

                    If[failureQ[promised] === False,
                        callback[promised],
                        callback[StringTemplate["Request failed: ``"][failureQ[promised] ] ];
                    ];                    
                ] ];
            ,
                Echo[StringTemplate["\nUsing API: `` result: ``\n"][path, result] ];

                If[failureQ[result] === False,
                    callback[result],
                    callback[StringTemplate["Request failed: ``"][failureQ[result] ] ];
                ];
            ]
        ]
    ] ];
]

tool = <||>;

tool["manage_todo_list"] = <|
  "Description" -> <|
    "type" -> "function",
    "function" -> <|
      "name" -> "manage_todo_list",
      "description" ->
        "TODO list tool for AI agents. Actions: list, add, complete.",
      "parameters" -> <|
        "type" -> "object",
        "properties" -> <|
          "action" -> <|
            "type" -> "string",
            "enum" -> {"list", "add", "complete"},
            "description" -> "Operation to perform."
          |>,
          "text" -> <|
            "type" -> "string",
            "description" -> "Required for action=\"add\"."
          |>,
          "id" -> <|
            "type" -> "string",
            "description" -> "For action=\"complete\": item id to mark complete."
          |>,
          "index" -> <|
            "type" -> "integer",
            "description" -> "For action=\"complete\": 1-based index (fallback if id not provided)."
          |>
        |>,
        "required" -> {"action"}
      |>
    |>
  |>,
  "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
    With[{n = notebook["ChatBook"]},
      If[! ListQ[n["TODO_List"] ], n["TODO_List"] = {}];

      AppendTo[
        toolsQue,
        Function[Null,
          Module[{action, result, text, id, idx, pos, item},
            action = ToLowerCase @ ToString @ Lookup[args, "action", "list"];

            result = Switch[action,

              "list",
              <|
                "ok" -> True,
                "items" -> n["TODO_List"],
                "count" -> Length[n["TODO_List"]]
              |>,

              "add",
              text = StringTrim @ ToString @ Lookup[args, "text", ""];
              If[text === "",
                <|"ok" -> False, "error" -> "Missing or empty \"text\"."|>,
                item = <|
                  "id" -> CreateUUID["todo-"],
                  "text" -> text,
                  "done" -> False
                |>;
                n["TODO_List"] = Append[n["TODO_List"], item];
                <|"ok" -> True, "item" -> item|>
              ],

              "complete",
              id = Lookup[args, "id", Missing["NA"]];
              idx = Lookup[args, "index", Missing["NA"]];

              pos = Which[
                StringQ[id] && id =!= "",
                FirstPosition[
                  n["TODO_List"],
                  _Association?(Lookup[#, "id", None] === id &),
                  Missing["NotFound"]
                ],
                IntegerQ[idx],
                If[1 <= idx <= Length[n["TODO_List"]], {idx}, Missing["NotFound"]],
                True,
                Missing["NotFound"]
              ];

              If[pos === Missing["NotFound"],
                <|"ok" -> False, "error" -> "Item not found. Provide valid \"id\" or 1-based \"index\"."|>,
                item = n["TODO_List"][[Sequence @@ pos]];
                item = Join[item, <|"done" -> True|>];
                n["TODO_List"][[Sequence @@ pos]] = item;
                <|"ok" -> True, "item" -> item|>
              ],

              _,
              <|"ok" -> False, "error" -> "Unknown action. Use: list, add, complete."|>
            ];

            toolResults[[myIndex]] = ExportString[result, "JSON", "Compact" -> True];
          ]
        ]
      ];
    ],
    HoldRest
  ]
|>;


tool["consult_docs"] = <|
    "Description" ->     <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "consult_docs", 
    		"description" -> "If 'id' is provided, returns the content of the docs item by id as a string. If 'id' is not provided, returns a list of all items with their title and id fields.", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "id" -> <|
                        "type"-> "string",
                        "description"-> "id of docs item"
                    |>
                |>
    		|>
    	|>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        With[{},
            If[KeyExistsQ[args, "id"],
                With[{item = library[ ToString[removeQuotes @ args["id"] ] ]},
                    AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                        If[!MatchQ[item, _Association], "ERROR: Not found by given id",
                            item["content"]
                        ]
                    ] ];
                ],
                AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                       ExportString[ Map[Function[val, <|"title"->val["title"], "id"->val["hash"]|>], library ]//Values, "JSON"];
                ] ];
            ]
        ]
    , HoldRest]
|>;

(* 
   Tool: list_cells
   Lists all cells in a notebook with metadata (Id, Type, Display, Lines, FirstLine)
*)
tool["list_cells"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "list_cells",
            "description" -> "List all cells in a notebook. Returns array of cell metadata including Id, Type (Input/Output), Display format, line count, and first line preview. Use this to get cell IDs for subsequent operations.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <||>
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/list/", <|
                "Notebook" -> notebook["Hash"]
            |>, Function[result,
                toolResults[[myIndex]] = ExportString[result, "JSON"];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: get_focused_cell
   Gets the currently focused cell and selection info
*)
tool["get_focused_cell"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "get_focused_cell",
            "description" -> "Get the currently focused cell in a notebook and its selection. Returns cell Id, type (Input or Output), Display format, line count, first line, and SelectedLines range [start, end] if text is selected. Useful for targeted edits based on user's cursor position.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <||>
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/focused/", <|
                "Notebook" -> notebook["Hash"]
            |>, Function[result,
                toolResults[[myIndex]] = ExportString[result, "JSON"];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: get_cell_lines
   Read specific lines from a cell
*)
tool["get_cell_lines"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "get_cell_lines",
            "description" -> "Read specific lines from a cell. Line numbers are 1-indexed. Returns the content as a string with newlines.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The cell hash ID"
                    |>,
                    "from" -> <|
                        "type" -> "integer",
                        "description" -> "Starting line number (1-indexed, inclusive)"
                    |>,
                    "to" -> <|
                        "type" -> "integer",
                        "description" -> "Ending line number (1-indexed, inclusive)"
                    |>
                |>,
                "required" -> {"cell", "from", "to"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/getlines/", <|
                "Cell" -> removeQuotes @ args["cell"],
                "From" -> args["from"],
                "To" -> args["to"]
            |>, Function[result,
                toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"]];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: set_cell_lines
   Replace a range of lines in a cell
*)
tool["set_cell_lines"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "set_cell_lines",
            "description" -> "Replace a range of lines in a cell with new content. Lines From (inclusive, 1-indexed) through To (inclusive, 1-indexed) are replaced. The new content can have fewer or more lines than the replaced range.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The cell hash ID"
                    |>,
                    "from" -> <|
                        "type" -> "integer",
                        "description" -> "Starting line number to replace (1-indexed, inclusive)"
                    |>,
                    "to" -> <|
                        "type" -> "integer",
                        "description" -> "Ending line number to replace (1-indexed, inclusive)"
                    |>,
                    "content" -> <|
                        "type" -> "string",
                        "description" -> "New content to insert (can contain newlines)"
                    |>
                |>,
                "required" -> {"cell", "from", "to", "content"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/setlines/", <|
                "Cell" -> removeQuotes @ args["cell"],
                "From" -> args["from"],
                "To" -> args["to"],
                "Content" -> args["content"]
            |>, Function[result,
                toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"]];
                EventFire[p, Resolve, True];
                WebUISubmit[vfx`MagicWand[removeQuotes @ args["cell"] ], socket];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: set_cell_lines_batch
   Apply multiple non-overlapping line edits in one call
*)
tool["set_cell_lines_batch"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "set_cell_lines_batch",
            "description" -> "Apply multiple non-overlapping line replacements to a cell in one call. Changes are automatically sorted and applied bottom-to-top to preserve line indices. More efficient than multiple set_cell_lines calls.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The cell hash ID"
                    |>,
                    "changes" -> <|
                        "type" -> "array",
                        "description" -> "Array of changes to apply. Each change has From, To, and Content.",
                        "items" -> <|
                            "type" -> "object",
                            "properties" -> <|
                                "from" -> <|"type" -> "integer", "description" -> "Starting line (1-indexed, inclusive)"|>,
                                "to" -> <|"type" -> "integer", "description" -> "Ending line (1-indexed, inclusive)"|>,
                                "content" -> <|"type" -> "string", "description" -> "Replacement content"|>
                            |>,
                            "required" -> {"from", "to", "content"}
                        |>
                    |>
                |>,
                "required" -> {"cell", "changes"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/setlines/batch/", <|
                "Cell" -> removeQuotes @ args["cell"],
                "Changes" -> Map[<|"From" -> #["from"], "To" -> #["to"], "Content" -> #["content"]|> &, args["changes"]]
            |>, Function[result,
                toolResults[[myIndex]] = ExportString[result, "JSON"];
                WebUISubmit[vfx`MagicWand[removeQuotes @ args["cell"] ], socket];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: insert_cell_lines
   Insert new lines without replacing existing content
*)
tool["insert_cell_lines"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "insert_cell_lines",
            "description" -> "Insert new lines into a cell without replacing existing content. Lines are inserted after the specified line number. Use after=0 to insert at the beginning.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The cell hash ID"
                    |>,
                    "after" -> <|
                        "type" -> "integer",
                        "description" -> "Insert after this line number (0 = insert at beginning)"
                    |>,
                    "content" -> <|
                        "type" -> "string",
                        "description" -> "Content to insert (can contain newlines)"
                    |>
                |>,
                "required" -> {"cell", "after", "content"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/insertlines/", <|
                "Cell" -> removeQuotes @ args["cell"],
                "After" -> args["after"],
                "Content" -> args["content"]
            |>, Function[result,
                toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"] ];
                WebUISubmit[vfx`MagicWand[removeQuotes @ args["cell"] ], socket];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: add_cell
   Add a new cell to the notebook
*)
tool["add_cell"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "add_cell",
            "description" -> "Add a new input cell to the notebook. Specify position with 'after' or 'before' cell ID. If neither specified, appends to notebook. Returns the new cell's ID.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "content" -> <|
                        "type" -> "string",
                        "description" -> "The cell content (code or text)"
                    |>,
                    "after" -> <|
                        "type" -> "string",
                        "description" -> "Insert after this cell ID (optional)"
                    |>,
                    "before" -> <|
                        "type" -> "string",
                        "description" -> "Insert before this cell ID (optional)"
                    |>,
                    "hidden" -> <|
                        "type" -> "boolean",
                        "description" -> "If true, the cell is hidden from view (optional, default: false)"
                    |>
                |>,
                "required" -> {"content"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            With[{body = <|
                "Notebook" -> notebook["Hash"],
                "Content" -> args["content"],
                If[KeyExistsQ[args, "after"], "After" -> removeQuotes @ args["after"], Nothing],
                If[KeyExistsQ[args, "before"], "Before" -> removeQuotes @ args["before"], Nothing],
                If[KeyExistsQ[args, "hidden"], "Hidden" -> args["hidden"], Nothing]
            |>},
                makeAPIRequest["/api/notebook/cells/add/", body, Function[result,
                    toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"]];
                    WebUISubmit[vfx`MagicWand[ result ], socket];
                    EventFire[p, Resolve, True];
                ] ];
            ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: add_cells_batch
   Add multiple cells in sequence
*)
tool["add_cells_batch"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "add_cells_batch",
            "description" -> "Add multiple input cells to a notebook in sequence. Cells are inserted one after another. More efficient than multiple add_cell calls. Returns array of created cell IDs.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "after" -> <|
                        "type" -> "string",
                        "description" -> "Insert cells after this cell ID (optional)"
                    |>,
                    "before" -> <|
                        "type" -> "string",
                        "description" -> "Insert first cell before this ID, rest chain after (optional)"
                    |>,
                    "cells" -> <|
                        "type" -> "array",
                        "description" -> "Array of cells to create",
                        "items" -> <|
                            "type" -> "object",
                            "properties" -> <|
                                "content" -> <|"type" -> "string", "description" -> "Cell content"|>,
                                "hidden" -> <|"type" -> "boolean", "description" -> "If true, cell is hidden (optional)"|>
                            |>,
                            "required" -> {"content"}
                        |>
                    |>
                |>,
                "required" -> {"cells"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            With[{body = <|
                "Notebook" -> notebook["Hash"],
                "Cells" -> Map[<|
                    "Content" -> #["content"],
                    If[KeyExistsQ[#, "hidden"], "Hidden" -> #["hidden"], Nothing]
                |> &, args["cells"]],
                If[KeyExistsQ[args, "after"], "After" -> removeQuotes @ args["after"], Nothing],
                If[KeyExistsQ[args, "before"], "Before" -> removeQuotes @ args["before"], Nothing]
            |>},
                makeAPIRequest["/api/notebook/cells/add/batch/", body, Function[result,
                    toolResults[[myIndex]] = ExportString[result, "JSON"];
                    WebUISubmit[vfx`MagicWand[ # ]&/@ result, socket];
                    EventFire[p, Resolve, True];
                ] ];
            ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: delete_cell
   Delete a cell from the notebook
*)
tool["delete_cell"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "delete_cell",
            "description" -> "Delete a cell from the notebook. Cannot delete output cells directly - delete their parent input cell instead.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The cell hash ID to delete"
                    |>
                |>,
                "required" -> {"cell"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/delete/", <|
                "Cell" -> removeQuotes @ args["cell"]
            |>, Function[result,
                toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"]];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: evaluate_cell
   Evaluate a cell and get output cell IDs
*)
tool["evaluate_cell"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "evaluate_cell",
            "description" -> "Evaluate an input cell in the notebook's kernel. Returns array of output cell [ID, Type, Display, Lines, FirstLine] after evaluation completes. The notebook must be open.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The input cell hash ID to evaluate"
                    |>
                |>,
                "required" -> {"cell"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/evaluate/", <|
                "Cell" -> removeQuotes @ args["cell"]
            |>, Function[result,
                toolResults[[myIndex]] = ExportString[result, "JSON"];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: project_cell
   Open cell content in a separate window
*)
tool["project_cell"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "project_cell",
            "description" -> "Project a cell's content into a standalone window. Useful for presentations, slides, or focused viewing of graphics.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "cell" -> <|
                        "type" -> "string",
                        "description" -> "The cell hash ID to project"
                    |>
                |>,
                "required" -> {"cell"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/notebook/cells/project/", <|
                "Cell" -> removeQuotes @ args["cell"]
            |>, Function[result,
                toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"]];
                EventFire[p, Resolve, True];
            ] ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: kernel_evaluate
   Evaluate an expression directly in the kernel
*)
tool["kernel_evaluate"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "kernel_evaluate",
            "description" -> "Evaluate a Wolfram Language expression directly in the kernel without needing an open notebook or cell. Returns the result as a string.",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "expression" -> <|
                        "type" -> "string",
                        "description" -> "Wolfram Language expression to evaluate (e.g., '1 + 1' or 'Plot[Sin[x], {x, 0, 2Pi}]')"
                    |>
                |>,
                "required" -> {"expression"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            With[{body = <|
                "Expression" -> args["expression"]
            |>},
                makeAPIRequest["/api/kernel/evaluate/", body, Function[result,
                    toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"] ];
                    EventFire[p, Resolve, True];
                ] ];
            ];
            p
        ] ] ];
    , HoldRest]
|>;

(* 
   Tool: wolfram_alpha
   Query Wolfram Alpha for short answers
*)
tool["wolfram_alpha"] = <|
    "Description" -> <|
        "type" -> "function",
        "function" -> <|
            "name" -> "wolfram_alpha",
            "description" -> "Query Wolfram Alpha for a short answer. Good for factual questions, calculations, unit conversions, and general knowledge queries. Returns a text string (max 1000 chars).",
            "parameters" -> <|
                "type" -> "object",
                "properties" -> <|
                    "query" -> <|
                        "type" -> "string",
                        "description" -> "The natural language query for Wolfram Alpha (e.g., 'what is the capital of France', 'convert 5 miles to km')"
                    |>
                |>,
                "required" -> {"query"}
            |>
        |>
    |>,
    "Function" -> Function[{myIndex, args, toolsQue, toolResults, notebook, socket},
        AppendTo[toolsQue, Function[Null, With[{p = Promise[]},
            makeAPIRequest["/api/alphaRequest/", <|
                "Query" -> args["query"]
            |>, Function[result,
                toolResults[[myIndex]] = If[StringQ[result], result, ExportString[result, "JSON"] ];
                EventFire[p, Resolve, True];
            ] ];        
            p
        ]  ] ];
    , HoldRest]
|>;


basisChatFunction[_] := Values[tool][[All, "Description"]]


toolsQue = {};

toolsQueNext := With[{},
    If[Length[toolsQue] > 0 ,
        Echo["toolsQueNext >> exec >>"];
        
        With[{first = (toolsQue // First)[]},
            Then[first, Function[Null,
                toolsQue = Drop[toolsQue, 1];
                toolsQueNext;
            ] ];
        ]
    ,
        Echo["toolsQueNext >> end"];
    ]
] 

toolsQue /: AppendTo[toolsQue, func_] := With[{}, Module[{}, 
    If[Length[toolsQue] === 0,
        toolsQue = Append[toolsQue, func];
        toolsQueNext;
    ,
        toolsQue = Append[toolsQue, func];
    ]
] ]



createChat[assoc_Association] := With[{
    client = assoc["Client"],
    logger = assoc["Messanger"],
    notebook = assoc["Notebook"],
    globalControls = assoc["Controls"]
},
    Module[{
        chat,
        functionsHandler,
        setContent,
        printCell,
        encodingError,
        APIError,
        last
    },

        loadSettings[settings];


        focused := notebook["FocusedCell"];


        encodingError[body_] := (
            chat["Messages"] = Append[chat["Messages"], <|
                                    "content" -> "Encoding error! <b>Cannot interprete the request</b>. Please reset the chat by sending <code>reset chat</code>. <br/> <p>Compressed message: "<>Compress[body]<>"</p>",
                                    "role" -> "watchdog",
                                    "date" -> Now
                                |>];                            

            EventFire[chat, "Update", chat["Messages"] ];
        );

        APIError[err_] := (
            chat["Messages"] = Append[chat["Messages"], <|
                                    "content" -> StringJoin[err, "\n", "Please reset the chat by sending <code>reset chat</code>"],
                                    "role" -> "watchdog",
                                    "date" -> Now
                                |>];                            

            EventFire[chat, "Update", chat["Messages"] ];
        );

        functionsHandler[a_Association, cbk_] := Module[{toolResults = {}, callIndex = 0, totalCalls},
            Echo["AI request >>"];

            totalCalls = Length[a["tool_calls"] ];
            (* Pre-allocate toolResults with placeholders to preserve order *)
            toolResults = Table[Null, totalCalls];

            Function[call,
                (* Capture current index for this specific call *)
                With[{myIndex = ++callIndex},
                With[{
                    args = ImportByteArray[StringToByteArray @
						call["function", "arguments"]
                        , "RawJSON", CharacterEncoding -> "UTF-8"
					],
                    name = call["function", "name"]
                },
                    tool[name]["Function"][myIndex, args, toolsQue, toolResults, notebook, client];
                ]
            ] ] /@ a["tool_calls"];

            AppendTo[toolsQue, Function[Null, 
                Echo["AI >> Tools que is empty now"];
                cbk[toolResults];
            ] ];
        ];

        initializeChat := (
            systemPromt = Uncompress[getParameter["AIAssistantAssistantPrompt"] ];

            With[{promt = systemPromt},
                chat = GPTChatObject[promt, 
                    "ToolFunction"->basisChatFunction, 
                    "ToolHandler"->functionsHandler, 
                    "APIToken"->getToken, 

                    "Endpoint" -> getParameter["Endpoint"],
                    "Temperature" -> getParameter["Temperature"],
                    "Model" -> getParameter["Model"],
                    "MaxTokens" -> getParameter["MaxTokens"],

                    "Logger"->Function[x, 
                        If[StringQ[x["Error"] ],
                            APIError[x["Error"] ]
                        ,
                            EventFire[chat, "Update", chat["Messages"] ] 
                        ]
                    ] ]
                ;
            ];

            notebook["ChatBook"] = chat;
            chat
        );

        initializeChat;

        With[{uid = CreateUUID[], c = chat},
            AIChat`HashMap[uid] = c;
            c["Hash"] = uid;

            If[c["Shown"] // TrueQ,
                WebUIClose[c["Socket"] ];
                SetTimeout[WebUILocation["/gptchat?id="<>uid, client, "Target"->_, "Features"->"width=460, height=640, top=0, left=800"], 300];
            ,
                WebUILocation["/gptchat?id="<>uid, client, "Target"->_, "Features"->"width=460, height=640, top=0, left=800"];
            ];

            
            EventHandler[EventClone[notebook], {
                "OnClose" -> Function[Null,
                    notebook["ChatBook"] = .;
                    AIChat`HashMap[uid] = .;
                    If[c["Shown"] // TrueQ,
                        WebUIClose[c["Socket"] ];
                    ];
                    Delete[c];
                    Echo["AI Chat was destoryed"];
                ]
            }];

            EventHandler[chat, {"Comment" -> Function[payload,
                If[StringMatchQ[ToLowerCase[payload], "reset chat"~~___],

                    notebook["ChatBook"] = .;
                    AIChat`HashMap[uid] = .;
                    If[c["Shown"] // TrueQ,
                        WebUIClose[c["Socket"] ];
                    ];
                    Delete[c];
                    WebUISubmit[Siriwave["Stop"], client ];
                    Echo["AI Chat was destoryed"];


                ,
                    WebUISubmit[Siriwave["Start", "canvas-palette-back"], client ];
                    Echo["Appending to chat:"];
                   
                    Then[GPTChatCompletePromise[ chat, payload ], Function[Null,
                        WebUISubmit[Siriwave["Stop"], client ];
                    ] ]; 
                ];
            ]}];
        ];




        chat
    ]
]


getToken := SystemCredential["WLJSAI_API_KEY"]

checkToken := With[{
    token = getToken
},
    StringQ[token]
]

handle[data_Association] := Module[{}, With[{
    
},
    Echo["AI Message"];


    If[$VersionNumber < 14.0, 
        EventFire[data["Messanger"], "Warning", "Wolfram Engine Version 14.0 or higher is required"];
        Return[Null];
    ];

    If[!checkToken, 
        EventFire[data["Messanger"], "Warning", "API Key was not found. Please, enter a valid one"];
        With[{requestPromise = Promise[]},
            Then[requestPromise, Function[token,
                If[StringQ[token],
                    getToken = StringTrim[token];
                    SystemCredential["WLJSAI_API_KEY"] = StringTrim[token];
                    handle[data];
                ];
            ] ];

            EventFire[data["Modals"], "TextBox", <|
                "Promise"->requestPromise, "title"->"Please, paste your API Key here", "default"-> ""
            |>];
        ];
        Return[Null];
    ];


    WebUISubmit[Siriwave["Start", "canvas-palette-back"], data["Client"] ];

    With[{assoc = Join[data, <|"Notebook" -> getNotebook[data]|> ]},
        If[MatchQ[assoc["Notebook"]["ChatBook"], _GPTChatObject],
            Echo["Reuse a chat!"];

            If[!(assoc["Notebook"]["ChatBook"]["Shown"] // TrueQ),
                WebUILocation["/gptchat?id="<>assoc["Notebook"]["ChatBook"]["Hash"], data["Client"], "Target"->_, "Features"->"width=460, height=640, top=0, left=800"];
            ];

            Then[GPTChatCompletePromise[ assoc["Notebook"]["ChatBook"], makePromt[assoc] ], Function[Null,
                WebUISubmit[Siriwave["Stop"], data["Client"] ];
                
            ] ]; 
        ,
            Echo["Create a chat!"];
            Then[GPTChatCompletePromise[ createChat[assoc], makePromt[assoc] ], Function[Null,
                WebUISubmit[Siriwave["Stop"], data["Client"] ];
                
            ] ];        
        ]

    ];

] ]

EventHandler[SnippetsEvents, {"InvokeAI" -> handle}];

If[getParameter["AIAssistantAutocomplit"],
    If[checkToken,
        Get[FileNameJoin[{$rootDir, "src", "Autocomplete.wl"}] ];
    ];
];

End[]
EndPackage[]