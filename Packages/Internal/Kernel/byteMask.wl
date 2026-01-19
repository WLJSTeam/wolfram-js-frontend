Module[{
	libLoad,
	module
},
	libLoad[v_] := 	LibraryFunctionLoad[File[FileNameJoin[{
									$InputFileName // DirectoryName // ParentDirectory, 
									"LibraryResources", ToString[v], $SystemID,
									"internal." <> Internal`DynamicLibraryExtension[]}] 
						], "byteMask", {
    					{LibraryDataType[ByteArray], "Shared"},
    						Integer, 
    						"ByteArray", 
    						Integer
  						}, 
  						"ByteArray"
	];

	If[FailureQ[
		libraryFunction = libLoad[7]
	],
		If[FailureQ[
			libraryFunction = libLoad[6]
		],
			ClearAll[libLoad];
			With[{c = Compile[{
			        {maskingKey, _Integer, 1},
			        {payload, _Integer, 1}
		        }, 
			        (*Return: PacketArray::[MachineInteger, 1]*)
			        Table[BitXor[payload[[i]], maskingKey[[Mod[i - 1, 4] + 1]]], {i, 1, Length[payload]}]
		        ]},
                Function[{key, len1, payload, len2},
                    c[payload // Normal, key // Normal]
                ]	
            ]
		,
			ClearAll[libLoad];
			libraryFunction
		]
	,
		ClearAll[libLoad];
		libraryFunction
	]
] // Quiet

(*With[{c = Compile[{
        {maskingKey, _Integer, 1},
        {payload, _Integer, 1}
    }, 
        (*Return: PacketArray::[MachineInteger, 1]*)
        Table[BitXor[payload[[i]], maskingKey[[Mod[i - 1, 4] + 1]]], {i, 1, Length[payload]}]
    ]},
    Function[{key, len1, payload, len2},
        c[payload // Normal, key // Normal]
    ]	
]*)
