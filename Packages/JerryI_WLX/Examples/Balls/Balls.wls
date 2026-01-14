#!/usr/bin/env wolframscript
(* ::Package:: *)
SetDirectory[FileNameJoin[{If[StringQ[NotebookDirectory[]], NotebookDirectory[], DirectoryName[$InputFileName]]}]]

Uncompress["1:eJx1T8tuwjAQDBT1wo0/6Ac0vveKKAoNCJoDZ5NugsXGtrwbBf6edawKLlzG+5rxzMfJ/TZvWZbRVKBomkms5wLfBmF1NcR0qN6lL/fbfMC0j4Q18
PM80mkmcDR8TlexK0Ug7SKnAh5f9F0aRoGi8y5wVUp5Zvb0pVTQQ96KTn/qCULtLIPlvHad2kAIt0IN+Imu1uh1fdEtkOq0seoHggVUydForuJgbJsCLgSWTj7r7d/q6gMQGWfT
Lt7KLPp4ZPq3+qz0Iv6Yddcj3gGoDVPG"];

PacletRepositories[{
  Github -> "https://github.com/KirillBelovTest/Objects",
  Github -> "https://github.com/JerryI/Internal",
  Github -> "https://github.com/JerryI/CSocketListener" -> "dev2024",
  Github -> "https://github.com/JerryI/TCPServer",
  Github -> "https://github.com/JerryI/HTTPHandler",
  Github -> "https://github.com/JerryI/WebSocketHandler",
  Github -> "https://github.com/JerryI/wl-misc" -> "dev",
  Github -> "https://github.com/JerryI/wl-wljs-packages"
}]

ENV = <|
    "WSPort"->8011,
    "HTTPPort"->8010,
    "Host"->"127.0.0.1"
|>

ENV["HAddr"] := StringTemplate["``:``"][ENV["Host"], ENV["HTTPPort"]]
ENV["WAddr"] := StringTemplate["``:``"][ENV["Host"], ENV["WSPort"]]

<<KirillBelov`Objects`
<<KirillBelov`Internal`
<<KirillBelov`CSockets`
<<KirillBelov`TCPServer`

<<KirillBelov`HTTPHandler`
<<KirillBelov`HTTPHandler`Extensions`

<<KirillBelov`WebSocketHandler`

Get[FileNameJoin[{ParentDirectory[Directory[]]//ParentDirectory,"Kernel", "WLX.wl"}]]
Get[FileNameJoin[{ParentDirectory[Directory[]]//ParentDirectory,"Kernel", "Importer.wl"}]]
Get[FileNameJoin[{ParentDirectory[Directory[]]//ParentDirectory,"Kernel", "WLJS.wl"}]]

(* Event handling and WLJS communication *)
<<JerryI`Misc`Events`
<<KirillBelov`CSockets`EventsExtension`
<<JerryI`Misc`WLJS`Transport`
<<JerryI`Misc`Async`

<<JerryI`WLJSPM`

WLJS`PM`Repositories[{
  Github -> "https://github.com/JerryI/wljs-interpreter" -> "dev",
  Github -> "https://github.com/JerryI/wljs-sharedlib-d3" -> "master",
  Github -> "https://github.com/JerryI/wljs-graphics-d3" -> "dev",
  Github -> "https://github.com/JerryI/wljs-inputs" -> "dev"
}]

$DefaultSerializer = ExportByteArray[#, "ExpressionJSON"]&


(* import libs data *)
Map[Function[path,
    Block[{System`$RemotePackageDirectory = FileNameJoin[{"wljs_packages", FileNameSplit[path] // First}]},
        FileNameJoin[{"wljs_packages", path}] // Get // Quiet;
    ];
], WLJS`PM`Includes["kernel"] ];

Print["Staring HTTP server..."];

tcp = TCPServer[];
tcp["CompleteHandler", "HTTP"] = HTTPPacketQ -> HTTPPacketLength;
tcp["MessageHandler", "HTTP"] = HTTPPacketQ -> http;


Main = ImportComponent["Main.wlx"];
FileRequestQ[request_] := (!MissingQ[request["Query"]["file"]])

http = HTTPHandler[];

http["MessageHandler", "FileJS"]  = GetFileRequestQ[{"js", "css"}] -> Function[request,
  ImportFile[request, "Base" -> {"wljs_packages"}] 
]

http["MessageHandler", "File"]  = FileRequestQ -> Function[request,
  ImportFile[request, "Base" -> {Directory[]}] 
]

http["MessageHandler", "Index"] = AssocMatchQ[<|"Method" -> "GET"|>] -> Main

(* ::End::*)
httplistener =  SocketListen[CSocketOpen[ENV["HAddr"]], tcp@# &]


Print["Staring WS/HTTP server..."];

wcp = TCPServer[]
wcp["CompleteHandler", "WebSocket"] = WebSocketPacketQ -> WebSocketPacketLength
wcp["MessageHandler", "WebSocket"]  = WebSocketPacketQ -> ws

ws = WebSocketHandler[]

ws["MessageHandler", "Evaluate"]  = Function[True] -> WLJSTransportHandler

WLJSTransportHandler["AddTracking"] = Function[{symbol, name, cli, callback},
    Print["Add tracking... for "<>name];
    Experimental`ValueFunction[Unevaluated[symbol]] = Function[{y,x}, callback[cli, x]];
, HoldFirst]

WLJSTransportHandler["GetSymbol"] = Function[{expr, client, callback},
    Print["evaluating the desired symbol on the Kernel"];
    callback[expr // ReleaseHold];
]

SocketListen[CSocketOpen[ENV["WAddr"]], wcp@#&, "SocketEventsHandler"->CSocketsClosingHandler];

SetAttributes[Offload, HoldFirst];

StringTemplate["open http://``"][ENV["HAddr"]] // Print;
While[True, Pause[1]];

