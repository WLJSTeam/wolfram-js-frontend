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

defaultSysPrompt = Compress[Import[FileNameJoin[{$rootDir, "rules.default.txt"}], "Text"] ];

getParameter[key_] := With[{
        params = Join[<|
            "AIAssistantEndpoint" -> "https://api.openai.com", 
            "AIAssistantModel" -> "gpt-4o-mini", 
            "AIAssistantMaxTokens" -> 70000, 
            "AIAssistantTemperature" -> 0.7,
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
With[{libItems = Table[Import[i, "Text"], {i, FileNames["*.txt", FileNameJoin[{$rootDir, "promts"}] ]}], stopList = getParameter["AIAssistantLibraryStopList"]},
    Map[
        With[{hash = CreateUUID[], content = ParseFrontMatter[#]},
            library[hash] = Join[<|
                "hash" -> hash,
                "words" -> ToString[WordCount[#] ],
                "enabled" -> (!MemberQ[stopList, content["title"] ])
            |>, content ];
        ]&    
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
            Echo["Got"];
            Echo[result];
            result
    ,
            Echo["rejected"];
            EventFire[assoc["Messanger"], "Warning", "There is no opened notebook" ];
            $Failed
    ]
]


parse[data_Association, notebook_nb`NotebookObj, responce_String] := With[{},
    Echo["Parsing..."];
    If[MatchQ[notebook["FocusedCell"], _cell`CellObj], 
        With[{o = notebook["FocusedCell"]},
            print[responce, o, "Notebook" -> notebook]
        ]
    ,
        print[responce, Null, "Notebook" -> notebook]
    ];
]

print[message_String, after_, opts__] := Module[{list, last = Null, add},
    list = StringSplit[message, StartOfLine ~~ "```"];

    add[rules__] := With[{},
        If[last === Null,
            
            Print["Print directly..."];
            If[after =!= Null,
                last = cell`CellObj["After"->Sequence[after, ___?cell`OutputCellQ], rules, opts];
            ,
                last = cell`CellObj[rules, opts];
            ];
     
        ,
            Print["Print after something..."];
            last = cell`CellObj["After"->last, rules, opts]
           
        ]
    ];

    toCode[#, add, Null] &/@ list;

    ClearAll[add];
]

removeFirstLine[str_String] := StringDrop[str, StringLength[First[StringSplit[str, "\n"] ] ] ] // StringTrim

toCode[text_String, add_, eval_] := 
Module[{rest = StringTrim[text]},


	Which[
		StringMatchQ[text, {"md", "markdown"} ~~ __, IgnoreCase -> True], 
            add["Data"->(".md\n" <> removeFirstLine[rest]), "Display"->"codemirror", "Type"->"Input"]
        , 
			
		StringMatchQ[text, {"js", "javascript"} ~~ __, IgnoreCase -> True], 
			add["Data"->(".js\n" <> removeFirstLine[rest]), "Display"->"codemirror", "Type"->"Input"]
        , 
   
  		StringMatchQ[text, {"mermaid"} ~~ __, IgnoreCase -> True], 
			add["Data"->(".mermaid\n" <> removeFirstLine[rest]), "Display"->"codemirror", "Type"->"Input"] // eval;
        , 
			
		StringMatchQ[text, {"html"} ~~ __, IgnoreCase -> True], 
            add["Data"->(".html\n" <> removeFirstLine[rest]), "Display"->"codemirror", "Type"->"Input"] // eval;
        , 
			
		StringMatchQ[text, {"wolfram", "mathematica"} ~~ __, IgnoreCase -> True], 
			add["Data"->removeFirstLine[rest], "Display"->"codemirror", "Type"->"Input"];
        , 
			
		True, 
            With[{processed = StringReplace[StringReplace[text, {"\\"->"\\\\"}], {"\\\\[" -> "\n$$\n", "\\\\]" -> "\n$$\n", "&"->"", "\\\\begin{align*}" -> "", "\\\\end{align*}" -> "", "\\\\begin{align}" -> "", "\\\\end{align}" -> ""}]},
			    add["Data"->(".md\n" <> processed), "Display"->"codemirror", "Type"->"Input", "Props"-><|"Hidden"->True|>];
                add["Data"->processed, "Display"->"markdown", "Type"->"Output"];
            ]
	]
]

trimContent[str_String] := With[{splitted = If[Length[#] == 0, {str}, #] &@ StringSplit[str, "\n"]},
    With[{content = If[StringMatchQ[splitted // First, "."~~WordCharacter..],
        StringRiffle[Rest[splitted], "\n"]
    ,
        str
    ]},
        content
    ]
]

checkLanguage[cell_cell`CellObj] := If[cell`InputCellQ[cell], With[{splitted = StringSplit[cell["Data"], "\n"]},
    If[Length[splitted] === 0, "Wolfram Language",
        If[StringMatchQ[splitted // First, "."~~WordCharacter..],
            StringReplace[StringTrim[splitted // First], {
                ".js" -> "Javascript",
                ".md" -> "Markdown",
                ".html" -> "HTML",
                ".wlx" -> "Wolfram XML",
                ".mermaid" -> "Mermaid",
                ".slides" -> "Aggregation revealjs cell (do not read or edit!!!)",
                ".slide" -> "Slide"
            }]
        ,
            "Wolfram Language"
        ] 
    ]
],
    (*find parent*)
    With[{parent = cell`FindCell[cell["Notebook"], Sequence[_?cell`InputCellQ, ___?cell`OutputCellQ, cell] ]},
        If[MatchQ[parent, _cell`CellObj],
            checkLanguage[parent]
        ,
            Echo["ERROR >> PARENT CELL NOT FOUND!!!"];
            Echo[parent];
            Echo[cell];

            "Wolfram Language"
        ]
    ]
]

restoreLanguage[_, _Missing] := ""
restoreLanguage[_Missing, _] := ""

restoreLanguage[lang_, content_] := Which[
    StringMatchQ[lang, {"Wolfram", "Mathematica"} ~~ ___, IgnoreCase -> True],
    content,

    StringMatchQ[lang, {"Aggregation revealjs cell (do not read or edit!!!)"} ~~ ___, IgnoreCase -> True],
    StringJoin[".slides\n", content],

    StringMatchQ[lang, {"RevealJS", "Reveal", "Reveal.JS", "Reveal JS", "Slide"} ~~ ___, IgnoreCase -> True],
    StringJoin[".slide\n", content],
    
    StringMatchQ[lang, {"HTML", "XML"} ~~ ___, IgnoreCase -> True],
    StringJoin[".html\n", content],

    StringMatchQ[lang, {"Wolfram XML"} ~~ ___, IgnoreCase -> True],
    StringJoin[".wlx\n", content],    

    StringMatchQ[lang, {"Javascript", "JS"} ~~ ___, IgnoreCase -> True],
    StringJoin[".js\n", content],

    StringMatchQ[lang, {"Markdown", "MD"} ~~ ___, IgnoreCase -> True],
    StringJoin[".md\n", content],

    StringMatchQ[lang, {"Mermaid"} ~~ ___, IgnoreCase -> True],
    StringJoin[".mermaid\n", content],

    True,
    content
]

basisChatFunction[_] := {
    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "getCellList", 
    		"description" -> "returns a flat list of cells in the notebook in the form [uid, type, contentType, hidden]. to get actual content use getCellContentById", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <||>
    		|>
    	|>
    |>,

    (*<|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "getLibraryList", 
    		"description" -> "returns a flat list of available knowledge (library item) in local library about the execution enviroment in the form [uid, title, desc]. to get actual content use getLibraryItemById", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <||>
    		|>
    	|>
    |>,  *)  

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "getFocusedCell", 
    		"description" -> "returns an information of a cell focused by a user in a form [uid, type, contentType, hidden]. To get actual content use getCellContentById", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <||>
    		|>
    	|>
    |>, 

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "getSelectedText", 
    		"description" -> "returns an selected code or text by a user as a string. Use setSelectedText to replace the selected content", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <||>
    		|>
    	|>
    |>,   

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "setSelectedText", 
    		"description" -> "replaces users selected text or code to a new string provided. Returns empty string", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "content" -> <|
                        "type"-> "string",
                        "description"-> "new content"
                    |> 
                |>
    		|>
    	|>
    |>,  

           

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "getLibraryItemById", 
    		"description" -> "returns a library item content by id in a form of a string", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "id" -> <|
                        "type"-> "string",
                        "description"-> "id of library item"
                    |>
                |>
    		|>
    	|>
    |>, 

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "getCellContentById", 
    		"description" -> "returns the content of a given cell by id in a form of a string", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "uid" -> <|
                        "type"-> "string",
                        "description"-> "uid of a cell"
                    |>
                |>
    		|>
    	|>
    |>, 

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "setCellContentById", 
    		"description" -> "sets the content of a given input cell by id in a form of a string. Output cells cannot be changed. Returns empty string.", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "uid" -> <|
                        "type"-> "string",
                        "description"-> "uid of a cell"
                    |>,
                    "content" -> <|
                        "type"-> "string",
                        "description"-> "content"
                    |>                                       
                |>
    		|>
    	|>
    |>,    

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "createCell", 
    		"description" -> "creates a new input cell after another cell specified by uid or adds it to the end of the notebook if argument \"after\" is not provided. Returns an uid of created cell", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "after" -> <|
                        "type"-> "string",
                        "description"-> "uid of a cell after it will be added"
                    |>,                  
                    "content" -> <|
                        "type"-> "string",
                        "description"-> "content"
                    |>,
                    "contentType" -> <|
                        "type"-> "string",
                        "description"-> "programming language or content type used"
                    |>                                                           
                |>
    		|>
    	|>
    |>,  

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "toggleCell", 
    		"description" -> "show or hide an input cell by uid in the notebook. Output cells cannot be changed. Returns empty string", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "uid" -> <|
                        "type"-> "string",
                        "description"-> "uid of a cell"
                    |>                                                          
                |>
    		|>
    	|>
    |>,

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "deleteCell", 
    		"description" -> "deletes any cell (input or output) by uid in the notebook. By deleting input cell, all next output cell will also be removed. Returns empty string", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "uid" -> <|
                        "type"-> "string",
                        "description"-> "uid of a cell"
                    |>                                                          
                |>
    		|>
    	|>
    |>,

    
    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "wolframAlphaRequest", 
    		"description" -> "make textual request to WolframAlpha and returns result as a short answer", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "request" -> <|
                        "type"-> "string",
                        "description"-> "request text"
                    |>                                                          
                |>
    		|>
    	|>
    |>,

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "evaluateCell", 
    		"description" -> "evaluates an input cell by uid in the notebook. Returns JSON string of messages generated and output cells IDs. Note: (1) it may show encoded expression for large Wolfram Expressions, apply Short to see the shorten form; (2) markdown, javascript output only a user can see in the notebook, you will see the same input expression", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "uid" -> <|
                        "type"-> "string",
                        "description"-> "uid of a cell to be evaluated"
                    |>                                                          
                |>
    		|>
    	|>
    |>,

    <|
    	"type" -> "function", 
    	"function" -> <|
    		"name" -> "evaluateExpression", 
    		"description" -> "directly evaluate a single Wolfram Expression in the notebook context and return the output with generated messages", 
    		"parameters" -> <|
    			"type" -> "object", 
    			"properties" -> <|
                    "expression" -> <|
                        "type"-> "string",
                        "description"-> "input expression"
                    |>                                                          
                |>
    		|>
    	|>
    |>     

}


wolframAlphaRequest[query_String] := With[{str = ImportString[ExportString[
 WolframAlpha[query, "ShortAnswer"], 
  "Table",   CharacterEncoding -> "ASCII"
 ],  "String"]},
  If[!StringQ[str], "$Failed",
    If[StringLength[str] > 1000, 
      StringTake[str, Min[StringLength[str], 1000] ]<>"..."
    ,
      str
    ]
  ]
];

toolsQue = {};

toolsQueNext := With[{},
    If[Length[toolsQue] > 0 ,
        Echo["toolsQueNext >> exec >>"];
        Echo[(toolsQue // First) // Short];
        
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

truncateIfLarge[str_String] := If[StringLength[str] > 3000, StringTake[str,3000]<>"...", str]



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
        Echo["Focused cell"];
        Echo[focused];

        Echo["Notebook:"];
        Echo[notebook];

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
        

        removeQuotes[str_String] := If[StringTake[str, 1] === "\"", StringDrop[StringDrop[str, -1], 1], str ];

        functionsHandler[a_Association, cbk_] := Module[{toolResults = {}, callIndex = 0, totalCalls},
            Echo["AI request >>"];
            Echo[Print[a] ];

            totalCalls = Length[a["tool_calls"]];
            (* Pre-allocate toolResults with placeholders to preserve order *)
            toolResults = Table[Null, totalCalls];

            Function[call,
                (* Capture current index for this specific call *)
                Module[{myIndex = ++callIndex},
                With[{result = Switch[call["function", "name"],

                    "setSelectedText",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"], "RawJSON", CharacterEncoding -> "UTF-8"
									]},

                            If[FailureQ[args], 
                                encodingError[call["function", "arguments"] ];
                                Return[];
                            ];

                            AppendTo[toolsQue, Function[Null,
                                WebUISubmit[FrontEditorSelected["Set", args["content"] ], client];
                                WebUISubmit[vfx`MagicWand[ "frame-"<>focused["Hash"] ], client];
                            ] ];

                            AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = "*Done*" ] ];
                        ]                        
                    ,

                    "getSelectedText",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"], "RawJSON", CharacterEncoding -> "UTF-8"
									],
                              promise = Promise[] 
                            },

                            If[FailureQ[args], 
                                encodingError[call["function", "arguments"] ];
                                Return[];
                            ];

                            AppendTo[toolsQue, Function[Null, promise ] ];                   
                               
                            Then[WebUIFetch[FrontEditorSelected["Get"], client, "Format"->"JSON"], Function[result,
                                If[!StringQ[result],
                                    toolResults[[myIndex]] = "*ERROR: Nothing is selected*";
                                    EventFire[promise, Resolve, True];
                                ,
                                    If[StringLength[result] === 0,
                                        toolResults[[myIndex]] = "*ERROR: Nothing is selected*";
                                        EventFire[promise, Resolve, True];                                    
                                    ,
                                        toolResults[[myIndex]] = result;
                                        EventFire[promise, Resolve, True];                                    
                                    ]
                                ];
                            ] ];

                        ]                        
                    ,                    

                    "getCellList",
                        AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = ExportString[Map[Function[cell, 
                            {cell["Hash"], cell["Type"], checkLanguage[ cell ], TrueQ[cell["Props"]["Hidden"] ]}
                        ], notebook["Cells"] ], "JSON"] ] ];
                    ,

                    "getLibraryList",
                        AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = ExportString[Map[Function[item, 
                            {item["hash"], item["title"], item["desc"]}
                        ], Select[Values[library], Function[i, i["default"] =!= True && i["enabled"] === True ] ] ], "JSON"] ] ];
                    ,

                    "getFocusedCell",
                        AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                            If[!MatchQ[focused, _cell`CellObj], "ERROR: Nothing is focused",
                                ExportString[{focused["Hash"], focused["Type"], checkLanguage[ focused ], TrueQ[focused["Props"]["Hidden"] ]}, "JSON"]
                            ]
                        ] ];
                    ,

                    "getCellContentById",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            With[{cell = cell`HashMap[ removeQuotes @ args["uid"] ]},
                                AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                                    If[!MatchQ[cell, _cell`CellObj], "ERROR: Not found by given id",
                                        trimContent[ cell["Data"] ]
                                    ]
                                ] ];
                            ] 
                        ]
                    ,

                    "getLibraryItemById",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            With[{item = library[ removeQuotes @ args["id"] ]},
                                AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                                    If[!MatchQ[item, _Association], "ERROR: Not found by given id",
                                        trimContent[ item["content"] ]
                                    ]
                                ] ];
                            ] 
                        ]
                    ,                    

                    "setCellContentById",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            
                            If[FailureQ[args], 
                                encodingError[call["function", "arguments"] ];
                                Return[];
                            ];

                            With[{cell = cell`HashMap[ removeQuotes @ args["uid"] ]},
                                AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                                    If[!MatchQ[cell, _cell`CellObj], "ERROR: Not found by given id",
                                        EventFire[cell, "ChangeContent", restoreLanguage[checkLanguage[ cell ], args["content"] ] ];
                                        WebUISubmit[vfx`MagicWand[ "frame-"<>cell["Hash"] ], client];
                                        "*Done*"
                                    ]
                                ] ];
                            ] 
                        ]
                    ,

                    "deleteCell",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            With[{cell = cell`HashMap[ removeQuotes @ args["uid"] ]},
                                AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] =
                                    If[!MatchQ[cell, _cell`CellObj], "ERROR: Not found by given id",
                                        Echo["AI Delete!!!"];

                                        Delete[cell];
                                        
                                    
                                    
                                        "*Done*"
                                    ]
                                ] ];
                            ] 
                        ]


                    ,                    

                    "toggleCell",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                    , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            With[{cell = cell`HashMap[ removeQuotes @ args["uid"] ]},
                                If[!MatchQ[cell, _cell`CellObj], "ERROR: Not found by given id",
                                    Echo["AI Toggle!!!"];


                                        AppendTo[toolsQue, Function[Null,
                                            Block[{Global`$Client = client}, 
                                                EventFire[globalControls, "ToggleCell", cell]
                                            ]
                                        ] ];      

                                        AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = "*Done*" ] ];                                  
                                ]
                            ] 
                        ]


                    ,

                    "wolframAlphaRequest",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                    , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = wolframAlphaRequest[ args["request"] ] ] ];
                        ]
                    ,

                    "evaluateCell",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            With[{cell = cell`HashMap[ removeQuotes @ args["uid"] ]},
                                If[!MatchQ[cell, _cell`CellObj], 
                                    AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = "ERROR: Not found by given id" ] ];
                                ,
                                    Echo["AI Evaluate!!!"];

                                        AppendTo[toolsQue, Function[Null, With[{bufferLength = Length[
                                            EventFire[logger, "MessagesList", True]
                                        ], p = Promise[]},
                                            Block[{Global`$Client = client}, 

                                                Then[EventFire[globalControls, "NotebookCellEvaluateTemporal", cell], Function[Null,
                                                    With[{
                                                        generated = Drop[EventFire[logger, "MessagesList", True], -bufferLength],
                                                        out = Select[cell`SelectCells[cell["Notebook"]["Cells"], Sequence[cell, __?cell`OutputCellQ] ], cell`OutputCellQ]
                                                    },
                                                        Echo["Generated messages: "];
                                                        Echo[generated];
                                                        Echo["Generated output cells: "];
                                                        Echo[#["Data"] &/@ out];

                                                        toolResults[[myIndex]] = ExportByteArray[<|"Messages"->generated, "Out"->(truncateIfLarge[#["Data"] ] &/@ out)|>, "JSON"] // ByteArrayToString;
                                                        EventFire[p, Resolve, True];
                                                    ]
                                                ] ];

                                                
                                            ];
                                            p
                                        ] ] ];
                                        
                                        
                                    
                           
                                ]
                            ] 
                        ]
                    ,     

                    "evaluateExpression", 
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},
                            With[{expr = removeQuotes @ args["expression"]},
                            AppendTo[toolsQue, Function[Null, With[{bufferLength = Length[
                                            EventFire[logger, "MessagesList", True]
                            ], p = Promise[], firstPromise = Promise[]},
                                Block[{Global`$Client = client}, 

                                    GenericKernel`Init[notebook["Evaluator"]["Kernel"], 
                                        EventFire[Internal`Kernel`Stdout[ firstPromise // First ], Resolve, ToString[ToExpression[expr, InputForm], InputForm] ];
                                    ];

                                    Then[firstPromise, Function[result,
                                        With[{
                                            generated = Drop[EventFire[logger, "MessagesList", True], -bufferLength]
                                        },
                                            Echo["Generated messages: "];
                                            Echo[generated];
                                            Echo["Generated output: "];
                                            Echo[result];

                                            toolResults[[myIndex]] = ExportByteArray[<|"Messages"->generated, "Result"->(truncateIfLarge[result ])|>, "JSON"] // ByteArrayToString;
                                            EventFire[p, Resolve, True];
                                        ]
                                    ] ];

                                    
                                ];
                                p
                            ] ] 
                                        
                                        
                                    
                           
                                ]
                            ] 
                        ]
                    ,                

                    "createCell",
                        With[{args = ImportByteArray[StringToByteArray @
										call["function", "arguments"]
                                        , "RawJSON", CharacterEncoding -> "UTF-8"
									]},

                            If[FailureQ[args], 
                                encodingError[call["function", "arguments"] ];
                                Return[];
                            ];

                            
                                With[{cell = cell`HashMap[ removeQuotes @ args["after"] ]},
                                    If[!MatchQ[cell, _cell`CellObj], 
                                    
                                        With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->restoreLanguage[args["contentType"], args["content"] ] ]},
                                            WebUISubmit[vfx`MagicWand[ "frame-"<>new["Hash"] ], client];
                                            AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = new["Hash"] ] ];
                                        ]                                        
                                    ,
                                        With[{new = cell`CellObj["Notebook"->notebook, "Type"->"Input", "Data"->restoreLanguage[args["contentType"], args["content"] ], "After"->cell]},
                                            WebUISubmit[vfx`MagicWand[ "frame-"<>new["Hash"] ], client];
                                            AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = new["Hash"] ] ];
                                        ]
                                    ]
                                ]
                            
                        ]

                    ,                    

                    _,
                        Echo["Undefined Function!"]; AppendTo[toolsQue, Function[Null, toolResults[[myIndex]] = "ERROR: Undefined Function!" ] ];
                ]},
                    1+1
                    
                ]
            ] ] /@ a["tool_calls"];

            AppendTo[toolsQue, Function[Null, 
                Echo["AI >> Add tool calls to the chat"];
                cbk[toolResults];
            ] ];
        ];

        initializeChat := (
            systemPromt = Uncompress[getParameter["AIAssistantAssistantPrompt"] ] <> "\n\n";
            If[getParameter["AIAssistantInitialPrompt"],
                systemPromt = systemPromt <> "\nNow some additional information that you should consider while assisting the user:\n";
                systemPromt = systemPromt <> StringRiffle[Select[Values[library], Function[i, i["default"] === True && i["enabled"] === True ] ][[All, "content"]]  ];

                systemPromt = systemPromt <> "\n\n**Here is a flat list of available knowledge (library items) in local library about the execution enviroment and frameworks in the form [uid, title, desc]**. Note: to get actual content use getLibraryItemById.\n\n" <> ExportString[Map[Function[item, 
                            {item["hash"], item["title"], item["desc"]}
                        ], Select[Values[library], Function[i, i["default"] =!= True && i["enabled"] === True ] ] ], "JSON"]<>"\n **END of list**.\n";
            ];


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
                    Echo[payload];
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
    Echo[chat];

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