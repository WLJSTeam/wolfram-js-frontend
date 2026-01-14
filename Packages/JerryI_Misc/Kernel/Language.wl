BeginPackage["JerryI`Misc`Language`"]; 

LeakyModule::usage = "Module, that leaks on purpose"

SafeTable::usage = "Table that stores results in array, so that any Abort signal will not wipe it"


Begin["`Private`"]; 


Garbage = {}

ExtractFirst[x_, y___] := FakeHold[x];
SetAttributes[ExtractFirst, HoldFirst];
SetAttributes[FakeHold, HoldFirst];

LeakyModule[vars_, expr_, OptionsPattern[]] := With[{garbage = OptionValue[Automatic, Automatic, "Garbage", Unevaluated]},
    Module[vars, CompoundExpression[
        AppendTo[garbage, (Hold[vars] /. {Set :> ExtractFirst} // ReleaseHold) /. {FakeHold -> Hold}],
        expr
    ]]
]

SetAttributes[LeakyModule, HoldAll]
Options[LeakyModule] = {"Garbage" :> Garbage}


SafeTable[expr_, dims_, OptionsPattern[]] := (
    With[{buffer = OptionValue["Buffer"]},
        ClearAll[buffer];
        Table[With[{res$ = expr}, buffer = Append[buffer, res$]; res$], dims]
    ]
)

SetAttributes[SafeTable, HoldAll]
Options[SafeTable] = {"Buffer" :> SafeTable`Buffer}


End[];

EndPackage[];
