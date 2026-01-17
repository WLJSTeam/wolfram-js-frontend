BeginPackage["CoffeeLiqueur`Extensions`Autocomplete`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`", 
    "JerryI`WLX`",
    "JerryI`WLX`Importer`",
    "JerryI`WLX`WebUI`", 
    "JerryI`WLX`WLJS`",
    "JerryI`Misc`WLJS`Transport`",    
    "KirillBelov`HTTPHandler`",
    "KirillBelov`HTTPHandler`Extensions`",
    "KirillBelov`Internal`",
    "KirillBelov`Objects`"
}]


Begin["`Private`"]

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];


rootDir = $InputFileName // DirectoryName // ParentDirectory;

defaults = Get[FileNameJoin[{rootDir, "src", "AutocompleteDefaults.wl"}] ];

defaults = Map[Function[p,
    If[KeyExistsQ[p, "info"], 
        Join[p, <|"info"->StringReplace[p["info"], {"\n"->"<br/>", "\[InvisibleSpace]"->""}]|>]
    ,
        p
    ]
], defaults];

EventHandler[AppExtensions`AppEvents// EventClone, {
    "Loader:NewNotebook" ->  (Once[ attachListeners[#] ] &),
    "Loader:LoadNotebook" -> (Once[ attachListeners[#] ] &)
}];


GetDefaults := With[{},
    <|"hash" -> Hash[defaults], "data" -> defaults|>
]


attachListeners[notebook_nb`NotebookObj] := With[{},
    Echo["Attach event listeners to notebook from EXTENSION"];
    EventHandler[notebook // EventClone, {
        "OnWebSocketConnected" -> Function[payload,
            GenericKernel`Init[notebook["Evaluator"]["Kernel"], Unevaluated[
                CoffeeLiqueur`Extensions`Autocomplete`Private`BuildVocabularAsync;
                CoffeeLiqueur`Extensions`Autocomplete`Private`StartTracking;
            ], "Once"->True];
         

            WebUISubmit[ Global`UIAutocompleteConnect[Hash[defaults] ], payload["Client"] ];
        ]
    }]; 
]

blackList[name_String] := MemberQ[{
    "PointLight",
    "SpotLight",
    "Graphics",
    "Manipulate",
    "EventHandler",
    "Button",
    "Animate",
    "Refresh",
    "Graphics3D",
    "Inset",
    "ListAnimate",
    "Image",
    "Image3D",
    "AnimatedImage",
    "Offload",
    "SystemOpen",
    "SystemInputDialog",
    "SystemDialogInput",
    "MessageDialog",
    "ChoiceDialog",
    "ChoiceDialogAsync",
    "Interpretation",
    "MakeBoxes",
    "ProgressIndicator",
    "StandardForm",
    "InputForm",
    "Rasterize",
    "Sound",
    "EchoLabel",
    "Beep",
    "CopyToClipboard",
    "Paste",
    "PasteButton",
    "ClickToCopy",
    "CellPrint",
    "EvaluationCell",
    "EvaluationNotebook",
    "Text",
    "Rasterize",
    "CreateDocument",
    "NotebookOpen",
    "NotebookWrite",
    "NotebookClose",
    "NotebookEvaluate"
}, name];


makeURL[name_] := With[{docs = Information[name]["Documentation"]},
        If[AssociationQ[docs] && !blackList[name],
            docs // First
        ,
           "https://wljs.io/search?q="<>URLEncode[StringTrim[name] ]
        ]
        
]

DocWindowHashMap = <||>;
initWindow[o_] := With[{uid = CreateUUID[]},
    o["UId"] = uid;
    DocWindowHashMap[uid] = o;
    o
];

CreateType[DocWindow, initWindow, {}];

DocWindow /: DeleteObject[d_DocWindow] := With[{uid = d["UId"]},
    DocWindowHashMap[uid] = .;
    Delete[d];
]

findDocWindow[cli_] := SelectFirst[Values[DocWindowHashMap], Function[d, d["AssociatedSocket"] === cli] ];

EventHandler["autocompleteFindDoc", Function[label, With[{cli = Global`$Client}, {w = findDocWindow[cli]},
    If[MissingQ[w],
        With[{doc = DocWindow["Label"->label, "URL"->makeURL[label], "AssociatedSocket"->cli]},
            WebUILocation["/docFind/"<>doc["UId"], cli, "Target"->_];
        ];
    ,
        w["URL"] = makeURL[label];
        w["Refresh"][];
    ]
] ] ];

docsWindow = ImportComponent[FileNameJoin[{rootDir, "templates", "Docs.wlx"}] ];

With[{http = AppExtensions`HTTPHandler},
    http["MessageHandler", "DocsFinder"] = AssocMatchQ[<|"Path" -> ("/docFind/"~~___)|>] -> docsWindow;
];


End[]
EndPackage[]
