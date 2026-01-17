BeginPackage["CoffeeLiqueur`Extensions`FileEditor`WL`", { 
    "CoffeeLiqueur`Notebook`Transactions`",
    "JerryI`Misc`Events`",
    "JerryI`WLX`",
    "JerryI`WLX`Importer`",
    "JerryI`WLX`WebUI`",
    "JerryI`Misc`WLJS`Transport`",
    "CoffeeLiqueur`Extensions`FrontendObject`",
    "JerryI`Misc`Async`"
}]

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Begin["`Internal`"]

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];
Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];


root = $InputFileName // DirectoryName // ParentDirectory;

AppExtensions`SidebarIcons = ImportComponent[FileNameJoin[{root, "templates", "Icons.wlx"}] ];

editorView = ImportComponent[ FileNameJoin[{root, "templates", "FileEditor.wlx"}] ];

WLFileQ[path_] := FileExtension[path] === "wl"

CoffeeLiqueur`Notebook`Views`Router[any_?WLFileQ, appevents_String] := With[{},
    Echo["WL File"];
    Echo[any];

    {editorView[any, ##], ""}
]&

End[]
EndPackage[]