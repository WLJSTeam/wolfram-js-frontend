#!/usr/bin/env wolframscript

PacletDirectoryUnload /@ PacletDirectoryLoad[]; (* FIXME WL autoloads some crap *)

ParentDirectory[DirectoryName[$InputFileName]] // SetDirectory;
PacletDirectoryLoad[Directory[]];

Get[FileNameJoin[{Directory[], "Common", "LPM", "LPM.wl"}] ];

Off[General::shdw]; (* avoid warning messages from ContextAliases *)
Off[Part::partd]; (* avoid warning messages from WLX *)

(* WLJS Package manager *)
Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];

With[{deps = Get[FileNameJoin[{Directory[], "dependencies.wl"}] ]},
  If[FailureQ[LPMLoad[ "Directory" -> Directory[] ] ], 
    Echo["wl_packages is empty"];

    DeleteDirectory[FileNameJoin[{Directory[], "wl_packages"}],   DeleteContents->True] // Quiet;
    DeleteDirectory[FileNameJoin[{Directory[], "wljs_packages"}], DeleteContents->True] // Quiet;
    DeleteFile[FileNameJoin[{Directory[], #}] ] &/@ {
      "wl_packages_lock.wl"
    } // Quiet;

    Echo["Installing all..."];
    LPMRepositories[Map[("Github"->#)&, deps["WL"] ], "Directory" -> Directory[] ];

    WLJSPackages`InstallAll[Map[("Github"->#)&, deps["WLJS"] ], "Directory" -> FileNameJoin[{Directory[], "wljs_packages"}] ];
  ,

    WLJSPackages`Load[FileNameJoin[{Directory[], "wljs_packages"}] ];
  ];
];


(* web-server *)
Needs["KirillBelov`CSockets`"]
Needs["KirillBelov`Objects`"]
Needs["KirillBelov`Internal`"]
Needs["KirillBelov`TCPServer`"]

Needs["KirillBelov`HTTPHandler`"]
Needs["KirillBelov`HTTPHandler`Extensions`"]
Needs["KirillBelov`WebSocketHandler`"]
Needs["KirillBelov`LTP`"]

Needs["LetWL`"]


Needs["CoffeeLiqueur`Notebook`Utils`"];

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];

Needs["CoffeeLiqueur`Notebook`Windows`" -> "win`"];

Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];

(* WLJS transport *)
Needs["JerryI`Misc`WLJS`Transport`"]

(* event system  *)
Needs["JerryI`Misc`Events`"]
Needs["JerryI`Misc`Events`Promise`"]

Needs["JerryI`Misc`Async`"]

Needs["JerryI`Misc`Parallel`"]



Needs["CoffeeLiqueur`Notebook`LocalKernel`" -> "LocalKernel`"];
Needs["CoffeeLiqueur`Notebook`Transactions`"]


Needs["KirillBelov`CSockets`EventsExtension`"]

(* WLX template engine *)
Needs["JerryI`WLX`"]
Needs["JerryI`WLX`Importer`"]
Needs["JerryI`WLX`WLJS`"]

(* WebUI Toolkit *)
Needs["JerryI`WLX`WebUI`"]

Needs["CodeParser`"]


(* env parameters *)
System`$Env;


$Env = Join[<|
  "host" -> "127.0.0.1",
  "http" -> 20560,
  "ws"   -> 20559,
  "jtp"  -> 20562,
  "ws2"  -> 20563,

  "wsprefix" -> False,
  "ws2prefix" -> False
  (*,"docs" -> 20540*)
|>, If[AssociationQ[$Env], $Env, <||> ] ];

If[$ScriptCommandLine =!= {},
  With[{argv = Rest @ $ScriptCommandLine},
    Echo["Command line: "];
    Echo[argv];
    MapIndexed[Function[{key, pos},
      With[{},
        If[MemberQ[Keys[$Env], key] || True,
          With[{
            value = argv[[2;;;;2]][[ pos[[1]] ]]
          },
            Echo[key -> value];
  
            $Env = Join[$Env, <|key -> If[NumericQ[ $Env[key] ],
              ToExpression[value],
              value
            ]|>];
          ]
        ]
      ]
    ], argv[[;;;;2]]];
  ];
];

If[KeyExistsQ[$Env, "folder"],
  $Env["parent_folder"] = ParentDirectory[ $Env["folder"] ];
];

With[{appJSON = Import[FileNameJoin[{Directory[], "package.json"}], "RawJSON"]},
  $Env["AppJSON"] = appJSON;
];


versionToNumber[ver_String] := FromDigits[ToExpression@StringSplit[ver, "."], 1000];

If[versionToNumber[$VersionNumber] > versionToNumber["14.2"],
  Echo["Warning: your Wolfram Kernel version is higher, that tested with WLJS Notebook. We do not guarantee it will work"];
];

If[versionToNumber[$VersionNumber] < versionToNumber["13.3"],
  Echo["Error: your Wolfram Kernel version is older than 13.3. WLJS App won't work. We are sorry"];
  Echo["You can always download a freeware Wolfram Engine"];
  Exit[-1];
];


syncDemoFolders[path_String] := Null;

AppExtensions`FrontendEnv = $Env;

AppExtensions`QuickNotesDir = FileNameJoin[{$TemporaryDirectory, "wljs_quicknotes"}];
If[!DirectoryQ[AppExtensions`QuickNotesDir], CreateDirectory[AppExtensions`QuickNotesDir] ];

AppExtensions`BackupsDir = FileNameJoin[{$TemporaryDirectory, "wljs_backups"}];
If[!DirectoryQ[AppExtensions`BackupsDir], CreateDirectory[AppExtensions`BackupsDir] ];

AppExtensions`DefaultDocumentsDir = FileNameJoin[{$UserDocumentsDirectory, "WLJS Notebooks"}];
If[!DirectoryQ[AppExtensions`DefaultDocumentsDir], CreateDirectory[AppExtensions`DefaultDocumentsDir] ];

AppExtensions`DemosDir = FileNameJoin[{AppExtensions`DefaultDocumentsDir, "Demos"}];
If[!DirectoryQ[AppExtensions`DemosDir], CreateDirectory[AppExtensions`DemosDir]; syncDemoFolders[AppExtensions`DemosDir]; ];

AppExtensions`ExtensionsDir = FileNameJoin[{AppExtensions`DefaultDocumentsDir, "Extensions"}];
If[!DirectoryQ[AppExtensions`ExtensionsDir], CreateDirectory[AppExtensions`ExtensionsDir]; ];

AppExtensions`AppDataDir = Lookup[$Env, "AppData", Directory[] ];

AppExtensions`AppConfig = FileNameJoin[{AppExtensions`AppDataDir, "_settings.wl"}];

If[KeyExistsQ[$Env, "store_config_in_docs"],
  AppExtensions`AppConfig = FileNameJoin[{AppExtensions`DefaultDocumentsDir, "config.wl"}];
];

(* ~~check version~~ *)
Echo["Checking version of WLJS Notebook ..."];
Echo[AppExtensions`FrontendEnv["AppJSON"]["version"] ];

Echo["Default paths:"];
Echo[">> QuickNotesDir: "<> AppExtensions`QuickNotesDir];
Echo[">> BackupsDir: "<> AppExtensions`BackupsDir];
Echo[">> DefaultDocumentsDir: "<> AppExtensions`DefaultDocumentsDir];
Echo[">> DemosDir: "<> AppExtensions`DemosDir];
Echo[">> ExtensionsDir: "<> AppExtensions`ExtensionsDir];
Echo[">> AppDataDir: "<> AppExtensions`AppDataDir];
Echo[">> AppConfig: "<> AppExtensions`AppConfig];
Echo[">> Root: "<> Directory[] ];

(* load users extensions *)
WLJSPackages`Load[ AppExtensions`ExtensionsDir ];

{loadSettings, storeSettings}        = Get[FileNameJoin[{"Frontend", "Settings.wl"}] ];

RandomWord[];



WLJSPackages`Includes["js"];
WLJSPackages`Includes["frontend"];

WLJSPackages`SyncShared[{FileNameJoin[{Directory[], "wljs_packages"}], AppExtensions`ExtensionsDir}, FileNameJoin[{AppExtensions`AppDataDir, "__shared"}] ];

(*EventHandler[AppExtensions`AppEvents // EventClone, {
 any_ :> (Echo[StringTemplate["App Event ``: ``"][any, #]]&)
}];*)

(* start a bit earlier, so that extensions can hook on*)
$Server = <||>;
$DefaultSerializer = ExportByteArray[#, "ExpressionJSON"]&

Print["Staring HTTP server..."];

tcp = TCPServer[];
tcp["CompleteHandler", "HTTP"] = HTTPPacketQ -> HTTPPacketLength;
tcp["MessageHandler", "HTTP"]  = HTTPPacketQ -> http;

http = HTTPHandler[];
$Server["HTTPHandler"] = http;

AppExtensions`HTTPHandler = http;


With[{now = Now},
  Function[file,
    If[now - FileDate[file] > Quantity[14, "Days"], DeleteFile[file]; Echo[StringTemplate["Removed old note ``"][file] ] ]
  ] /@ FileNames["*.wln", AppExtensions`QuickNotesDir]
];

With[{now = Now},
  Function[file,
    If[now - FileDate[file] > Quantity[30, "Days"], DeleteFile[file]; Echo[StringTemplate["Removed old note ``"][file] ] ]
  ] /@ FileNames["*.wln", AppExtensions`BackupsDir]
];


(* load stuff into frontend *)
Echo["Loading packages: FRONTEND"];

If[FailureQ[
    Get[
      UniversalPathConverter[#],
      Path->{FileNameJoin[{Directory[], "wljs_packages"}], AppExtensions`ExtensionsDir}
    ] 
  ],
  Echo["Failed to load some of the packages (see logs)"];
  Exit[0]
] &/@ WLJSPackages`Includes["frontend"]; 

JerryI`WLX`Importer`Private`CacheControl["Hour"];

AppExtensions`KernelList = {};


(* Entrypoint of an app *)
Sponsors       := ImportComponent["Frontend/Sponsors.wlx"];
ServerError       := ImportComponent["Frontend/ServerError.wlx"];
Protocol          := ImportComponent["Frontend/Protocol.wlx"];
ExtendedApp               := ImportComponent["Frontend/ExtendedApp.wlx"];
IframeApp    := ImportComponent["Frontend/IframeApp.wlx"];
App         := ImportComponent["Frontend/App.wlx"];
PromptWindow         := ImportComponent["Frontend/PromptWindow.wlx"];
Window      := ImportComponent["Frontend/Window.wlx"];
Settings    := ImportComponent["Frontend/Settings.wlx"];
Downloader   = ImportComponent["Frontend/Downloader.wl"];

(* Global variables *)

$ExposedDirectories = {FileNameJoin[{Directory[], "wljs_packages"}], FileNameJoin[{Directory[], "Assets"}], Directory[], AppExtensions`ExtensionsDir, "/", ""}
$ExposedRoutes = <||>;


EventHandler[AppExtensions`AppEvents // EventClone, {
 "Notebook:Close" -> Function[notebook,
  Print["Notebook was closed"];
  (*$ExposedDirectories = ReplacePart[$ExposedDirectories, FirstPosition[$ExposedDirectories, notebook["Path"] // DirectoryName ] -> Nothing];*)
 ],
 "Loader:NewNotebook" -> Function[notebook,
  Echo["New notebook load and add it to the path! >>"];

  If[MemberQ[notebook["Properties"], "WorkingDirectory"],
    $ExposedDirectories = Append[$ExposedDirectories, notebook["WorkingDirectory"] ]  // DeleteDuplicates;
  ,
    $ExposedDirectories = Append[$ExposedDirectories, notebook["Path"] // DirectoryName ]  // DeleteDuplicates;
  ];
 ],
 "Loader:LoadNotebook" -> Function[notebook,
  Echo["Load notebook and adding it to the path! >>"];
  

  If[MemberQ[notebook["Properties"], "WorkingDirectory"],
    Echo[notebook["WorkingDirectory"] ];
    $ExposedDirectories = Append[$ExposedDirectories, notebook["WorkingDirectory"] ] // DeleteDuplicates;
  ,
    Echo[notebook["Path"] // DirectoryName];
    $ExposedDirectories = Append[$ExposedDirectories, notebook["Path"] // DirectoryName ]  // DeleteDuplicates;
  ];
  
 ],

 "App:ExtendPath" -> Function[path,
  $ExposedDirectories = Append[$ExposedDirectories, path] // DeleteDuplicates;
 ],

 "App:ExtendRoute" -> Function[route,
  $ExposedRoutes = Join[$ExposedRoutes, route];
 ], 

 "App:RemovePath" -> Function[paths, Module[{p = $ExposedDirectories},
    $ExposedDirectories = p /. {paths -> Nothing};
  ] ]
}];




ElectronQ[request_] := (KeyExistsQ[request["Headers"], "Electron"]);
ElectronGetVersion[request_] := If[KeyExistsQ[request["Headers"], "Electron"], request["Headers", "Electron"], "false"];

(* serve static *)
AppExtensions`HTTPFileExtensions = {"jpeg", "wlx", "ttf",  "otf", "woff", "woff2", "css", "js", "png", "jpg", "webp", "svg", "pdf", "gif", "dat"};
http["MessageHandler", "File"]  = GetFileRequestQ[AppExtensions`HTTPFileExtensions] -> (
  ImportFile[#, "Base":>$ExposedDirectories, "Routes":>$ExposedRoutes] &
)

SocketListen[CSocketOpen[$Env["host"], $Env["http"]], tcp@#&]


Print["Staring WS/HTTP server..."];

wcp = TCPServer[]
wcp["CompleteHandler", "WebSocket"] = WebSocketPacketQ -> WebSocketPacketLength
wcp["MessageHandler", "WebSocket"]  = WebSocketPacketQ -> ws

ws = WebSocketHandler[]
$Server["WebSocketHandler"] = ws;

(* configure the handler for WLJS communications *)
ws["MessageHandler", "Evaluate"]  = Function[True] -> WLJSTransportHandler


SocketListen[CSocketOpen[$Env["host"], $Env["ws"] ], wcp@#&, "SocketEventsHandler"->CSocketsClosingHandler];

(* start all webservers from extensions *)
Map[Function[key, 
  With[{server = AppExtensions`WebServers[key]},
    Echo[StringTemplate["Starting App extension server `` on ``:``"][key, server["Host"], server["Port"]]];
    SocketListen[CSocketOpen[server["Host"], server["Port"]], server["Handler"]];
  ]
], Keys[AppExtensions`WebServers]];


(* reseved keyword for WLJS interpreter *)
SetAttributes[Offload, HoldFirst];

middleware[app_][request_] := app[request]

(* hook all routes handlers *)
AutoTest["HTTPHandler"->http];
Downloader["HTTPHandler"->http];
Sponsors["HTTPHandler"->http];
Protocol["HTTPHandler"->http, "AppProtocol" -> AppExtensions`AppProtocol, "Middleware"->Identity, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates, "ExtensionSidebarIcons"->AppExtensions`SidebarIcons, "Env"->$Env];
Settings["HTTPHandler"->http, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates]
Window["HTTPHandler"->http, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates];
PromptWindow["HTTPHandler"->http, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates, "ExtensionSidebarIcons"->AppExtensions`SidebarIcons, "Env"->$Env];
ExtendedApp["HTTPHandler"->http, "Middleware"->middleware, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates, "ExtensionSidebarIcons"->AppExtensions`SidebarIcons, "Env"->$Env];
IframeApp["HTTPHandler"->http, "Middleware"->middleware, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates, "ExtensionSidebarIcons"->AppExtensions`SidebarIcons, "Env"->$Env];
App["HTTPHandler"->http, "Middleware"->middleware, "AppEvent"->AppExtensions`AppEvents, "ExtensionTemplates"->AppExtensions`Templates, "ExtensionSidebarIcons"->AppExtensions`SidebarIcons, "Env"->$Env];


SetTimeout[
  StringTemplate["Open http://``:`` in your browser"][$Env["host"], $Env["http"]] // Print;
, 15000
];

SetTimeout[
  StringTemplate["Open http://``:`` in your browser"][$Env["host"], $Env["http"]] // Print;
, 10000
];

SetTimeout[
  StringTemplate["Open http://``:`` in your browser"][$Env["host"], $Env["http"]] // Print;
, 5000
];

SetTimeout[
  StringTemplate["Open http://``:`` in your browser"][$Env["host"], $Env["http"]] // Print;
, 3000
];

SetTimeout[
  StringTemplate["Open http://``:`` in your browser"][$Env["host"], $Env["http"]] // Print;
, 1000
];

(* Main sync thread *)

Looper[];
