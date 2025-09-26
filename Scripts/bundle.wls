#!/usr/bin/env wolframscript

PacletDirectoryUnload /@ PacletDirectoryLoad[]; (* FIXME WL autoloads some crap *)

ParentDirectory[DirectoryName[$InputFileName]] // SetDirectory;
PacletDirectoryLoad[Directory[]];

Get[FileNameJoin[{Directory[], "Common", "LPM", "LPM.wl"}] ];

deps = Get[FileNameJoin[{Directory[], "dependencies.wl"}] ];

LPMRepositories[Map[("Github"->#)&, deps["WL"] ], "Directory" -> Directory[], "MaxVersionDiff"-> 3 ]


(* WLJS Package manager *)
Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];


WLJSPackages`InstallAll[Map[("Github"->#)&, deps["WLJS"] ], "Directory" -> Directory[] , "MaxVersionDiff"-> 3]

