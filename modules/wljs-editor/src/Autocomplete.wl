BeginPackage["CoffeeLiqueur`Extensions`Autocomplete`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`", 
    "JerryI`WLX`WebUI`", 
    "KirillBelov`HTTPHandler`",
    "KirillBelov`HTTPHandler`Extensions`",
    "KirillBelov`Internal`"
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


makePage["WR", data_] := StringTemplate["<body><div style=\"height: 2rem;width: 100%;-webkit-app-region: drag;-webkit-user-select: none;\"></div><iframe style=\"width:100%;height:calc(100% - 2rem);border: none;border-radius: 7px; background: transparent;\" src=\"``\"></iframe></body>"][data] /; (System`$Env["ElectronCode"]===1);
makePage["WLJS", data_] := StringTemplate["<body><div style=\"height: 2rem;width: 100%;-webkit-app-region: drag;-webkit-user-select: none;\"></div><iframe style=\"width:100%;height:calc(100% - 2rem);border: none;border-radius: 7px; background: transparent;\" src=\"https://wljs.io/search?q=``\"></iframe></body>"][ data ] /; (System`$Env["ElectronCode"]===1);

makePage["WR", data_] := StringTemplate["<head><meta http-equiv='refresh' content='0; URL=``'></head><body></body>"][data];
makePage["WLJS", data_] := StringTemplate["<head><meta http-equiv='refresh' content='0; URL=https://wljs.io/search?q=``'></head><body></body>"][ data ];


docsFinder[request_] := With[{
    name = If[StringTake[#, -1] == "/", StringDrop[#, -1], #] &@ (StringReplace[request["Path"], ___~~"/docFind/"~~(n:__)~~EndOfString :> n])
},
    With[{docs = Information[name]["Documentation"]},
        If[AssociationQ[docs] && !blackList[name],
            makePage["WR", docs // First]
        ,
            makePage["WLJS", URLEncode[StringTrim[name] ] ]
        ]
        
    ]
]

With[{http = AppExtensions`HTTPHandler},
    http["MessageHandler", "DocsFinder"] = AssocMatchQ[<|"Path" -> ("/docFind/"~~___)|>] -> docsFinder;
];


End[]
EndPackage[]