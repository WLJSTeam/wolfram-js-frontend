
SnippetsCreateItem[
    "InvokeAI", 

    "Template"->ImportComponent[FileNameJoin[{iTemplate, "Magic.wlx"}] ], 
    "Title"->"Ask AI"
];

SnippetsCreateItem[
    "InstallPackage", 

    "Template"->ImportComponent[FileNameJoin[{iTemplate, "InstallPackage.wlx"}] ], 
    "Title"->"Install paclet from URL"
];

SnippetsCreateItem[
    "newFile", 

    "Template"->ImportComponent[FileNameJoin[{iTemplate, "File.wlx"}] ], 
    "Title"->"New notebook"
];

SnippetsCreateItem[
    "renameNotebook", 

    "Template"->ImportComponent[FileNameJoin[{iTemplate, "Rename.wlx"}] ], 
    "Title"->"Rename notebook"
];

SnippetsCreateItem[
    "printPDF", 

    "Template"->ImportComponent[FileNameJoin[{iTemplate, "Print.wlx"}] ], 
    "Title"->"Print"
];



NotebookQ[path_String] := FileExtension[path] === "wln"

EventHandler[SnippetsEvents, {
    "printPDF" -> Function[assoc, With[{notebook = (EventFire[assoc["Controls"], "NotebookQ", True] /. {{___, n_nb`NotebookObj, ___} :> n}) },

        If[MatchQ[notebook, _nb`NotebookObj] ,
            EventFire[assoc["Controls"], "PrintPDF", True];
        ,
            Echo["rejected"];
            EventFire[assoc["Messanger"], "Warning", "There is no opened notebook" ];
            
        ];
    ] ],
    "newFile" -> Function[assoc, EventFire[assoc["Controls"], "NewNotebook", <|"BaseDirectory"->(If[DirectoryQ[#], #, DirectoryName[#] ]&@ assoc["Path"])|>] ],
    "renameNotebook" -> Function[assoc, With[{notebook = (EventFire[assoc["Controls"], "NotebookQ", True] /. {{___, n_nb`NotebookObj, ___} :> n}) },

        If[MatchQ[notebook, _nb`NotebookObj] ,
            rename[notebook, assoc["Client"], assoc["Path"], assoc["Modals"], assoc["Controls"], assoc["Messanger"] ]
        ,
            Echo["rejected"];
            EventFire[assoc["Messanger"], "Warning", "There is no opened notebook" ];
            
        ];
    ] ]
}];


rename[notebook_nb`NotebookObj, cli_, path_, modals_, Controls_, log_] := (
  With[{requestPromise = Promise[]},
    With[{splitted = FileNameSplit[path], decoded = path},
      Then[requestPromise, Function[name,
        If[TrueQ[StringLength[StringTrim[name] ] > 0],
          If[FileExistsQ[FileNameJoin[Join[Drop[splitted, -1], {name<>".wln"} ] ] ],  
              EventFire[log, "Warning", "File exists!" ];
              Return[];
          ];

          If[!TrueQ[StringLength[name] > 3],  
              EventFire[log, "Warning", "Invalid filename" ];
              Return[];
          ];

          If[FileBaseName[Last[splitted] ] =!= name,
            EventFire[Controls, "RenameFile", {notebook, name<>".wln", cli}];
          ];
        ];
      ] ];

      EventFire[modals, "TextBox", <|
        "Promise"->requestPromise, "title"->"Enter new name", "default"-> FileBaseName[ Last[splitted] ]
      |>];
    ];
  ];
);
