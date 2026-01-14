BeginPackage["CoffeeLiqueur`Extensions`FileEditor`README`", { 
    "CoffeeLiqueur`Notebook`Transactions`",
    "JerryI`Misc`Events`",
    "JerryI`WLX`",
    "JerryI`WLX`Importer`",
    "JerryI`WLX`WebUI`",
    "JerryI`Misc`WLJS`Transport`",
    "JerryI`Misc`Async`"
}]

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Begin["`Internal`"]

Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];

root = $InputFileName // DirectoryName;

readmeView = ImportComponent[ FileNameJoin[{root, "README.wlx"}] ];

ReadmeQ[path_] := FileNameTake[path] === "README.md"

CoffeeLiqueur`Notebook`Views`Router[any_?ReadmeQ, appevents_String] := With[{},
    Echo["README File"];
    Echo[any];

    {readmeView[any, ##], ""}
]&

End[]
EndPackage[]