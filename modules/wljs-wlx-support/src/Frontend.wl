BeginPackage["CoffeeLiqueur`Extensions`WLXCells`", {
    "CoffeeLiqueur`Notebook`Transactions`",
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`"
}]


Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Begin["`Internal`"]

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];


Q[t_Transaction] := ( StringMatchQ[t["Data"], ".wlx"~~___] )

rootFolder = $InputFileName // DirectoryName;

evaluator  = StandardEvaluator`StandardEvaluator["Name" -> "WLX Evaluator", "InitKernel" -> init, "Pattern" -> (_?Q), "Priority"->(9)];

    StandardEvaluator`ReadyQ[evaluator, k_] := (
        If[! TrueQ[k["ReadyQ"] ] || ! TrueQ[k["ContainerReadyQ"] ],
            EventFire[k, "Error", "Kernel is not ready"];
            Print[evaluator, "Kernel is not ready"];
            False
        ,
            (* load kernels stuff. i.e. do it on demand, otherwise it takes too long on the startup *)
            (*With[{p = Import[FileNameJoin[{rootFolder, "Preload.wl"}], {"Package", "HeldExpressions"}]},
              Kernel`Init[k,  ReleaseHold /@ p; , "Once"->True];
            ];*)
            With[{p = Import[FileNameJoin[{rootFolder, "Preload.wl"}], "String"]},
                GenericKernel`Init[k,   ImportString[p, "WL"]; , "Once"->True];
            ];

            True
        ]
    );

StandardEvaluator`EvaluateTransaction[evaluator, k_, t_] := Module[{list},
    t["Evaluator"] = Internal`Kernel`WLXEvaluator;
    t["Data"] = StringDrop[t["Data"], 5];

    Print[evaluator, "GenericKernel`SubmitTransaction!"];
    GenericKernel`SubmitTransaction[k, t];    
];  

init[k_] := Module[{},
    Print["nothing to do..."];
]


End[]

EndPackage[]