#!/usr/bin/env wolframscript

PacletDirectoryUnload /@ PacletDirectoryLoad[]; (* FIXME WL autoloads some crap *)

ParentDirectory[DirectoryName[$InputFileName]] // SetDirectory;
PacletDirectoryLoad[Directory[]];

Get[FileNameJoin[{Directory[], "Common", "LPM", "LPM.wl"}] ];

DeleteFile /@ {
    ".wl_timestamp",
    ".wljs_timestamp"
};

PacletRepositories[{
  Github -> "https://github.com/KirillBelovTest/Objects" -> "master",
  Github -> "https://github.com/JerryI/Internal" -> "master",
  Github -> "https://github.com/JerryI/TCPServer" -> "master",
  Github -> "https://github.com/JerryI/HTTPHandler" -> "master",
  Github -> "https://github.com/JerryI/WebSocketHandler" -> "master",
  Github -> "https://github.com/JerryI/CSocketListener" -> "master",
  Github -> "https://github.com/JerryI/wl-wlx" -> "master",
  Github -> "https://github.com/JerryI/wl-misc" -> "main",
  Github -> "https://github.com/lshifr/LetWL" -> "master"
}, "Directory" -> Directory[], "MaxVersionDiff"-> 1 ]


(* WLJS Package manager *)
Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];


WLJSPackages`Repositories[{
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-editor" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/Mathematica-ThreeJS-graphics-engine" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-sharedlib-d3" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-sharedlib-mk" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-sharedlib-three" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-graphics-d3" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-html-support" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-inputs" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-interpreter" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-js-support" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-markdown-support" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-magic-support" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-plotly" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-cells" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-revealjs" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-wlx-support" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-mermaid-support" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-snippets" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-alt-cell-controls" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-print-redirect-fix" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-export-html" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-manipulate" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-sound" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-video" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-templates" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-xterm" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-excalidraw" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-toc" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-wxf-accelerator" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-neuralnet" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-docs-archive" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-demos-archive" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-debugger" -> "base",
  WLJSPackages`Github -> "https://github.com/JerryI/wljs-api" -> "base"
}, "Directory" -> Directory[], "MaxVersionDiff"-> 3 ]

Echo["Updated"];
Print["@Electron, go ahead"];