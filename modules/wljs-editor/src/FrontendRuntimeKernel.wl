

BeginPackage["CoffeeLiqueur`Extensions`RuntimeTools`", {
    "CoffeeLiqueur`Misc`Events`",
    "CoffeeLiqueur`Misc`Events`Promise`"
}]

Begin["`Internal`"]

Unprotect[Needs];
Needs::nonlocal = "Certain extensions are not available for remote kernels"
Protect[Needs]

submitAllExtensions[assoc_] := With[{promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "UpdateRuntimeExtensions", <|"Promise" -> (promise), "Kernel"->Internal`Kernel`Hash, "Data"->assoc|>];
    promise // WaitAll
]

extendHTTPPath["HTTP Serve", OptionsPattern[] ] := With[{
    promise = Promise[]
},
    With[{path = FileNameJoin[{pacletLocation, FileNameJoin @ OptionValue["Root"]}]},
        EventFire[Internal`Kernel`CommunicationChannel, "UpdateRuntimeHTTPPaths", <|"Promise" -> (promise), "Kernel"->Internal`Kernel`Hash, "Path"->path|>];
        promise // WaitAll        
    ]
]

extendHTTPRoute[route_Rule] := With[{
    promise = Promise[]
},
    With[{},
        EventFire[Internal`Kernel`CommunicationChannel, "UpdateRuntimeHTTPRoutes", <|"Promise" -> (promise), "Kernel"->Internal`Kernel`Hash, "Route"->Association[route]|>];
        promise // WaitAll        
    ]
]

Options[extendHTTPPath] = {"Root"->""}

(* rescan paclets every GET event *)

convertName[str_String] := StringReplace[str, {"\\"->"_", "/"->"_"}];

loadExtension["CSS", OptionsPattern[] ] := With[{root = OptionValue["Root"], location = FileNameJoin[{pacletLocation, FileNameJoin @ OptionValue["Root"]}]}, With[{
    key = {"Modules", "CSS", pacletName},
    imported = <|"Path"->FileNameSplit[#], "URL"-> StringRiffle[Join[{pacletName // convertName}, {root}//Flatten], "/"]|> &/@ If[DirectoryQ[location ],
        FileNames["*.css", location ]
    ,
        {location}
    ]
},
    key->imported
] ]

loadExtension["Javascript", OptionsPattern[] ] := With[{root = OptionValue["Root"], location = FileNameJoin[{pacletLocation, FileNameJoin @ OptionValue["Root"]}]}, With[{
    key = {"Modules", "Javascript", pacletName},
    imported = <|"Path"->FileNameSplit[#], "URL"-> StringRiffle[Join[{pacletName // convertName}, {root}//Flatten], "/"]|> &/@ If[DirectoryQ[location ],
        FileNames["*.js", location ]
    ,
        {location}
    ]
},
    key->imported
] ]

loadExtension["Javascript Bundle", OptionsPattern[] ] := With[{location = FileNameJoin[{pacletLocation, FileNameJoin @ OptionValue["Root"]}]}, With[{
    key = {"Bundles", "Javascript", pacletName},
    imported = Import[#, "Text"] &/@ If[DirectoryQ[location ],
        FileNames["*.js", location ]
    ,
        {location}
    ]
},
    key->imported
] ]

loadExtension["CSS Bundle", OptionsPattern[] ] := With[{location = FileNameJoin[{pacletLocation, FileNameJoin @ OptionValue["Root"]}]}, With[{
    key = {"Bundles", "CSS", pacletName},
    imported = Import[#, "Text"] &/@ If[DirectoryQ[location ],
        FileNames["*.css", location ]
    ,
        {location}
    ]
},
   key->imported
] ]

Options[loadExtension] = {"Root"->""}

rebuild[names_] := Map[Function[n,
    With[{
        p = PacletFind[n][[1]]
    },{
        extensions = p["Extensions"]
    },{
        selected = Select[extensions, MatchQ[#, {"CSS" | "Javascript" | "Javascript Bundle" | "CSS Bundle", __}]&],
        selectedPaths = Select[extensions, MatchQ[#, {"HTTP Serve", __}]&]
    },


        Block[{
            pacletLocation = p["Location"],
            pacletName = n
        }, 
        
            (extendHTTPPath @@ #) &/@ selectedPaths;

            If[Length[selected] > 0,
                extendHTTPRoute[{convertName[n], __} -> pacletLocation ];
            ];
        ]; 



        Association[Block[{
            pacletLocation = p["Location"],
            pacletName = n
        }, (loadExtension @@ #) &/@ selected] ] // submitAllExtensions;    
    ]
], names]

paclets = PacletFind["*"][[All, 1, "Name"]];

Internal`AddHandler["GetFileEvent",
 With[{new = PacletFind["*"][[All, 1, "Name"]]},
   With[{added = Complement[new, paclets]},
    If[Length[added] > 0, If[Internal`Kernel`Type === "LocalKernel",
        rebuild[added]
    ,
        Message[RuntimeTools::nonlocal];
    ] ];
   ];
   paclets = new;
 ]&
]

End[]
EndPackage[]
