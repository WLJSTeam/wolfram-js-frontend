BeginPackage["CoffeeLiqueur`Extensions`NotebookStorage`", {
    "CoffeeLiqueur`Extensions`Editor`",
    "CoffeeLiqueur`Misc`Events`",
    "CoffeeLiqueur`Misc`Events`Promise`"
}]

Begin["`Internal`"]

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

EventHandler[NotebookEditorChannel // EventClone,
    {
        "NotebookStoreGetKeys" -> Function[data,
           Echo["NotebookStore :: Get keys"];
           Echo[data];
           With[{promise = data["Promise"], notebook = nb`HashMap[ data["Ref"] ], kernel = GenericKernel`HashMap[ data["Kernel"] ]},
                If[!MemberQ[notebook["Properties"], "Storage"],
                    notebook["Storage"] = <||>;
                ];

                With[{keys = notebook["Storage"] // Keys},
                    GenericKernel`Async[kernel, EventFire[promise, Resolve, keys] ];
                ];
           ];
        ],

        "NotebookStoreGet" -> Function[data,
           With[{promise = data["Promise"], notebook = nb`HashMap[ data["Ref"] ], kernel = GenericKernel`HashMap[ data["Kernel"] ]},
                With[{value = notebook["Storage", data["Key"] ]},
                    GenericKernel`Async[kernel, EventFire[promise, Resolve, value] ];
                ];
           ];
        ],

        "NotebookStoreSet" -> Function[data,
           With[{promise = data["Promise"], payload = data["Data"], notebook = nb`HashMap[ data["Ref"] ], kernel = GenericKernel`HashMap[ data["Kernel"] ]},
                If[!MemberQ[notebook["Properties"], "Storage"],
                    notebook["Storage"] = <||>;
                ];

                notebook["Storage"] = Join[notebook["Storage"], <|data["Key"] -> payload|>];
                
                With[{value = data["Key"]},
                    GenericKernel`Async[kernel, EventFire[promise, Resolve, value] ];
                ];
           ];
        ],

        "NotebookStoreUnset" -> Function[data,
           With[{promise = data["Promise"], key = data["Key"], notebook = nb`HashMap[ data["Ref"] ], kernel = GenericKernel`HashMap[ data["Kernel"] ]},
                If[!MemberQ[notebook["Properties"], "Storage"],
                    notebook["Storage"] = <||>;
                ];

                notebook["Storage"] = KeyDrop[notebook["Storage"], key];
                
                With[{value = data["Key"]},
                    GenericKernel`Async[kernel, EventFire[promise, Resolve, value] ];
                ];
           ];
        ]              
    }
]

End[]
EndPackage[]