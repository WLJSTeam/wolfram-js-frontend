BeginPackage["CoffeeLiqueur`Extensions`MagicCells`", {
    "CoffeeLiqueur`Notebook`Transactions`",
    "JerryI`Misc`Events`"
}]

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Begin["`Internal`"]

Needs["CoffeeLiqueur`Notebook`Kernel`" -> "GenericKernel`"];
Needs["CoffeeLiqueur`Notebook`Evaluator`" -> "StandardEvaluator`"];


FileReadQ[t_Transaction] := (StringMatchQ[t["Data"], RegularExpression["^[\\w|\\d|\\-|\\_]*\\.[\\w]+$"]  ] )
filereader  = StandardEvaluator`StandardEvaluator["Name" -> "File Reader", "InitKernel" -> init, "Pattern" -> (_?FileReadQ), "Priority"->(9)];
StandardEvaluator`ReadyQ[filereader, k_] := True;
StandardEvaluator`EvaluateTransaction[filereader, k_, t_] := Module[{path, imported},
    path = FileNameJoin[{nb`HashMap[ t["EvaluationContext", "Notebook"] ]["Path"] // DirectoryName, StringTrim[ t["Data"] ]}];
    If[!FileExistsQ[path], 
        EventFire[t, "Error", "File "<>path<>" does not exist"];
        Return[$Failed];
    ];

    imported = Import[path, "String"];
    If[ByteCount[imported] > 30000,
        EventFire[t, "Error", "File "<>path<>" is too large to be displayed"];
        Return[$Failed];        
    ];

    EventFire[t, "Result", <|"Data"->imported, "Meta"->Sequence["Display"->"fileprint"]|>];
    EventFire[t, "Finished", True];    
];  


ImageReadQ[t_Transaction] := (StringMatchQ[t["Data"], RegularExpression["^[\\w|\\d|\\-|\\_]*\\.(png|jpg|jpeg|gif|svg|bmp|ttf|svg|webp)$"]  ] )
imagereader  = StandardEvaluator`StandardEvaluator["Name" -> "Image Reader", "InitKernel" -> init, "Pattern" -> (_?ImageReadQ), "Priority"->(8)];
StandardEvaluator`ReadyQ[imagereader, k_] := True;
StandardEvaluator`EvaluateTransaction[imagereader, k_, t_] := Module[{path, reducedPath},
    path = FileNameJoin[{nb`HashMap[ t["EvaluationContext", "Notebook"] ]["Path"] // DirectoryName, StringTrim[ t["Data"] ]}];
    If[!FileExistsQ[path], 
        EventFire[t, "Error", "File "<>path<>" does not exist"];
        Return[$Failed];
    ];

    reducedPath = StringTrim[ t["Data"] ];

    EventFire[t, "Result", <|"Data"->reducedPath, "Meta"->Sequence["Display"->"image"]|>];
    EventFire[t, "Finished", True];    
];  


FileWriteQ[t_Transaction] := (StringMatchQ[t["Data"], RegularExpression["^[\\w|\\d|\\-|\\_]*\\.[\\w]+\\n"]~~__  ] )
filewriter  = StandardEvaluator`StandardEvaluator["Name" -> "File Writer", "InitKernel" -> init, "Pattern" -> (_?FileWriteQ), "Priority"->(11)];
StandardEvaluator`ReadyQ[filewriter, k_] := True;
StandardEvaluator`EvaluateTransaction[filewriter, k_, t_] := Module[{path, file},
    path = FileNameJoin[{nb`HashMap[ t["EvaluationContext", "Notebook"] ]["Path"] // DirectoryName, StringCases[t["Data"], RegularExpression["^([\\w|\\d|\-|\\_]*\\.[\\w]+)\\n"] -> "$1"] // First // StringTrim }];

    If[FileExistsQ[path], DeleteFile[path] ];
    file = OpenWrite[path];
    WriteString[file, StringReplace[t["Data"], RegularExpression["^([\\w|\\d|\-|\\_]*\\.[\\w]+)\\n"] -> ""] ];
    file // Close;

    EventFire[t, "Result", <|"Data"->StringTemplate["``"][path], "Meta"->Sequence["Display"->"fileprint"]|>];
    EventFire[t, "Finished", True];    
];  

init[k_] := Null;


End[]

EndPackage[]
