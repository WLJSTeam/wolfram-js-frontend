BeginPackage["CoffeeLiqueur`Notebook`SettingsUtils`"];
Begin["`Internal`"];

loadConfiguration  := If[FileExistsQ[FileNameJoin[{CoffeeLiqueur`Notebook`AppExtensions`AppDataDir, "_settings.wl"}]], Get[FileNameJoin[{CoffeeLiqueur`Notebook`AppExtensions`AppDataDir, "_settings.wl"}]], Missing[]];
storeConfiguration[c_Association] := Put[c, FileNameJoin[{CoffeeLiqueur`Notebook`AppExtensions`AppDataDir, "_settings.wl"}] ];

initialize[conf_, OptionsPattern[] ] := With[{default = OptionValue["Defaults"]},
    conf = Join[default, (If[MissingQ[#], <||>, #]& ) @ loadConfiguration];
    storeConfiguration[conf]
];

SetAttributes[initialize, HoldFirst];
Options[initialize] = {"Defaults" -> <|"Autostart" -> True|>}

End[]
EndPackage[]

{CoffeeLiqueur`Notebook`SettingsUtils`Internal`initialize, CoffeeLiqueur`Notebook`SettingsUtils`Internal`storeConfiguration}