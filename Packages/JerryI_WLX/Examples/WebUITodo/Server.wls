#!/usr/bin/env wolframscript
(* ::Package:: *)
SetDirectory[If[StringQ[NotebookDirectory[] ], NotebookDirectory[], DirectoryName[$InputFileName] ] ]

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
  Github -> "https://github.com/JerryI/wl-wljs-packages", 
  Github -> "https://github.com/JerryI/wl-misc" -> "dev"
}]

RandomWord[];



(* Here you can configure *)
ENV = <|
    "WSPort"->8011,
    "HTTPPort"->8010,
    "Host"->"127.0.0.1"
|>

ENV["HAddr"] := StringTemplate["``:``"][ENV["Host"], ENV["HTTPPort"]]
ENV["WAddr"] := StringTemplate["``:``"][ENV["Host"], ENV["WSPort"]]

(* TCP Server *)
<<KirillBelov`Objects`
<<KirillBelov`Internal`
<<KirillBelov`CSockets`
<<KirillBelov`TCPServer`

(* HTTP services *)
<<KirillBelov`HTTPHandler`
<<KirillBelov`HTTPHandler`Extensions`

(* WS services *)
<<KirillBelov`WebSocketHandler`

Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "WLX.wl"}]]
Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "Importer.wl"}]]
Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "WLJS.wl"}]]
Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "WebUI.wl"}]]

(* Event handling and WLJS communication *)
<<JerryI`Misc`Events`
<<KirillBelov`CSockets`EventsExtension`
<<JerryI`Misc`WLJS`Transport`
<<JerryI`Misc`Async`

<<JerryI`WLJSPM`

$DefaultSerializer = ExportByteArray[#, "ExpressionJSON"]&


WLJS`PM`Repositories[{
  Github -> "https://github.com/JerryI/wljs-interpreter" -> "dev"
}]

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

(* our main file for all requests *)
App = ImportComponent["App.wlx"];

http = HTTPHandler[];

http["MessageHandler", "FileJS"]  = GetFileRequestQ[{"js", "css"}] -> Function[request,
  ImportFile[request, "Base" -> {"wljs_packages"}] 
]

http["MessageHandler", "Index"] = AssocMatchQ[<|"Method" -> "GET"|>] -> App

SocketListen[CSocketOpen[ENV["HAddr"]], tcp@#&]

Print["Staring WS/HTTP server..."];

wcp = TCPServer[]
wcp["CompleteHandler", "WebSocket"] = WebSocketPacketQ -> WebSocketPacketLength
wcp["MessageHandler", "WebSocket"]  = WebSocketPacketQ -> ws

ws = WebSocketHandler[]

(* configure the handler for WLJS communications *)
ws["MessageHandler", "Evaluate"]  = Function[True] -> WLJSTransportHandler

SocketListen[CSocketOpen[ENV["WAddr"]], wcp@#&, "SocketEventsHandler"->CSocketsClosingHandler]

StringTemplate["open http://``"][ENV["HAddr"]] // Print;
While[True, Pause[1]];

