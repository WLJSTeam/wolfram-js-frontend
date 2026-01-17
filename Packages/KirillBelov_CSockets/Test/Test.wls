#!/usr/bin/env wolframscript
(* ::Package:: *)
Uncompress["1:eJx1T8tuwjAQDBT1wo0/6Ac0vveKKAoNCJoDZ5NugsXGtrwbBf6edawKLlzG+5rxzMfJ/TZvWZbRVKBomkms5wLfBmF1NcR0qN6lL/fbfMC0j4Q18
PM80mkmcDR8TlexK0Ug7SKnAh5f9F0aRoGi8y5wVUp5Zvb0pVTQQ96KTn/qCULtLIPlvHad2kAIt0IN+Imu1uh1fdEtkOq0seoHggVUydForuJgbJsCLgSWTj7r7d/q6gMQGWfT
Lt7KLPp4ZPq3+qz0Iv6Yddcj3gGoDVPG"];

SetDirectory[If[StringQ[NotebookDirectory[] ], NotebookDirectory[], DirectoryName[$InputFileName] ] ]



PacletRepositories[{
  Github -> "https://github.com/KirillBelovTest/Objects",
  Github -> "https://github.com/JerryI/Internal",
  Github -> "https://github.com/JerryI/TCPServer",
  Github -> "https://github.com/JerryI/HTTPHandler",
  Github -> "https://github.com/JerryI/wl-wlx"
}]

PacletDirectoryLoad[ParentDirectory[Directory[] ] ]
<<KirillBelov`CSockets`

<<KirillBelov`Objects`
<<KirillBelov`Internal`
<<KirillBelov`TCPServer`

<<KirillBelov`HTTPHandler`
<<KirillBelov`HTTPHandler`Extensions`

<<JerryI`WLX`
<<JerryI`WLX`Importer`

Print["Staring HTTP server..."];

tcp = TCPServer[];
tcp["CompleteHandler", "HTTP"] = HTTPPacketQ -> HTTPPacketLength;
tcp["MessageHandler", "HTTP"] = HTTPPacketQ -> http;

app = ImportComponent["App.wlx"];


http = HTTPHandler[];

http["MessageHandler", "Index"] = AssocMatchQ[<|"Method" -> "GET"|>] -> app

(* ::End::*)
SocketListen[CSocketOpen["127.0.0.1:8010"], tcp@# &];


"open http://127.0.0.1:8010/"//Print;
While[True, Pause[1];];

