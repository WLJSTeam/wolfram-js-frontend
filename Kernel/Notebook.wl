BeginPackage["CoffeeLiqueur`Notebook`", {
    "CoffeeLiqueur`Misc`Events`", 
    "CoffeeLiqueur`Objects`"
}]

NotebookObj;

HashMap;
Serialize;
Deserialize;

Begin["`Private`"]

HashMap = <||>;

NullQ[any_] := any === Null

initNotebook[o_] := With[{uid = If[StringQ[o["Hash"] ] && o["Hash"] =!= Null, o["Hash"], CreateUUID[] ]},
    o["Hash"] = uid;
    HashMap[uid] = o;
    o
]


CreateType[NotebookObj, initNotebook, {"EvaluationContext"-><||>, "Cells"->{}}]

NotebookObj /: EventHandler[n_NotebookObj, opts__] := EventHandler[n["Hash"], opts] 
NotebookObj /: EventFire[n_NotebookObj, opts__] := EventFire[n["Hash"], opts]
NotebookObj /: EventClone[n_NotebookObj] := EventClone[n["Hash"]]
NotebookObj /: EventRemove[n_NotebookObj, opts__] := EventRemove[n["Hash"], opts] 

Serialize[n_NotebookObj] := Module[{props},
    props = {# -> n[#]} &/@ Complement[n["Properties"], {"Hash", "Format", "ChatBook", "CellsInitialized", "Socket", "EvaluationContext", "Opened","WebSocketQ", "Evaluator", "Cells", "Properties","Icon","Self", "Init", "Kernel"}];
    props // Flatten // Association
]

Deserialize[n_Association] := With[{notebook = NotebookObj[]},
    Deserialize[n["serializer"], n, notebook]
]

Deserialize[any_, n_Association, notebook_NotebookObj] := With[{},
    Echo["Notebook.wl >> Unknown Serializer: "];
    Echo[any];
    $Failed["Unknown Serializer: "<>ToString[any] ]
]

(* native WLJS format *)
Deserialize["jsfn4", n_Association, notebook_NotebookObj] := With[{},
    (notebook[#] = n["Notebook", #]) &/@ Complement[Keys[n["Notebook"] ], {"Hash"}]; 
    notebook["Cells"] = CoffeeLiqueur`Notebook`Cells`Deserialize[#, "Notebook"->notebook] &/@ n["Cells"];

    notebook
]

End[]
EndPackage[]