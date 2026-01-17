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
  Github -> "https://github.com/JerryI/wl-wljs-packages"
}]

<<KirillBelov`Objects`
<<KirillBelov`Internal`
<<KirillBelov`CSockets`
<<KirillBelov`TCPServer`

<<KirillBelov`HTTPHandler`
<<KirillBelov`HTTPHandler`Extensions`

<<JerryI`WLJSPM`

WLJS`PM`Repositories[{
  Github -> "https://github.com/JerryI/wljs-interpreter" -> "dev",
  Github -> "https://github.com/JerryI/wljs-sharedlib-d3" -> "master",
  Github -> "https://github.com/JerryI/wljs-graphics-d3" -> "dev"
}]

Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "WLX.wl"}]]
Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "Importer.wl"}]]
Get[FileNameJoin[{Directory[]//ParentDirectory//ParentDirectory,"Kernel", "WLJS.wl"}]]

Print["Staring HTTP server..."];

tcp = TCPServer[];
tcp["CompleteHandler", "HTTP"] = HTTPPacketQ -> HTTPPacketLength;
tcp["MessageHandler", "HTTP"] = HTTPPacketQ -> http;


index := ImportComponent["Components/Index.wlx"];

http = HTTPHandler[];

http["MessageHandler", "File"]  = GetFileRequestQ[{"css", "js"}] -> (
  ImportFile[#, "Base" -> {"wljs_packages"}] &
)

http["MessageHandler", "Index"] = AssocMatchQ[<|"Method" -> "GET"|>] -> Function[x, index[x]]

(* ::End::*)
SocketListen[CSocketOpen["127.0.0.1:8010"], tcp@# &];

"open http://127.0.0.1:8010" // Print;
While[True, Pause[1];];

