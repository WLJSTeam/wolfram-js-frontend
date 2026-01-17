BeginPackage["CoffeeLiqueur`Extensions`HTMLCells`", {
    "CoffeeLiqueur`Notebook`Transactions`",
    "JerryI`Misc`Events`",
    "WSP`"
}]


Begin["`Private`"]

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];


Internal`Kernel`HTMLEvaluator = Function[t, 
            
            With[{result = LoadString[ t["Data"] ]},
                EventFire[Internal`Kernel`Stdout[ t["Hash"] ], "Result", <|"Data" -> result, "Meta" -> Sequence["Display"->"html"] |> ];
                EventFire[Internal`Kernel`Stdout[ t["Hash"] ], "Finished", True];
            ];
];

End[]

EndPackage[]



