BeginPackage["CoffeeLiqueur`Extensions`NotebookStorage`", {
    "CoffeeLiqueur`Misc`Events`",
    "CoffeeLiqueur`Misc`Events`Promise`",
    "CoffeeLiqueur`Extensions`RemoteCells`"
}]

NotebookStore::usage = "NotebookStore[] represents an internal persistent storage of a notebook.\nNotebookWrite[NotebookStore[\"key\"], data] writes a data to a notebook.\nNotebookRead[NotebookStore[\"key\"]] read a data stored with a key\nNotebookRead[NotebookStore[{\"key1\", \"key2\", ..}]] read a data stored with keys"

Begin["`Private`"]


NotebookStore /: NotebookRead[NotebookStore[nb_RemoteNotebook, key_String] ] := WaitAll[NotebookReadAsync[NotebookStore[nb, key] ], 120]
NotebookStore /: NotebookRead[NotebookStore[nb_RemoteNotebook, keys:{__String}] ] := WaitAll[NotebookReadAsync[NotebookStore[nb, keys] ], 120]

NotebookStore /: NotebookRead[NotebookStore[key_String] ] := With[{nb = EvaluationNotebook[]}, NotebookRead[NotebookStore[nb, key] ] ]
NotebookStore /: NotebookRead[NotebookStore[keys: {__String}] ] := With[{nb = EvaluationNotebook[]}, NotebookRead[NotebookStore[nb, keys] ] ]


NotebookStore /: NotebookReadAsync[NotebookStore[key_String] ] := With[{nb = EvaluationNotebook[]}, NotebookReadAsync[NotebookStore[nb, key] ] ]
NotebookStore /: NotebookReadAsync[NotebookStore[keys:{__String}] ] := With[{nb = EvaluationNotebook[]}, NotebookReadAsync[NotebookStore[nb, keys] ] ]

NotebookStore /: NotebookReadAsync[NotebookStore[nb_RemoteNotebook, key_String] ] := With[{promise = Promise[], internalPromise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreGet", <|"Ref"->nb[[1]], "Key"->key, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        Then[promise, Function[r, 
            
            EventFire[internalPromise, Resolve, If[MissingQ[r], r, Uncompress[r] ]  ];
        ] ];
        internalPromise
] 

NotebookStore /: NotebookReadAsync[NotebookStore[nb_RemoteNotebook, keys: {__String}] ] := Map[NotebookReadAsync[NotebookStore[nb, #] ]&, keys]

NotebookStore /: NotebookWrite[NotebookStore[key_String], data_ ] := With[{nb = EvaluationNotebook[]}, NotebookWrite[NotebookStore[nb, key], data ] ]
NotebookStore /: NotebookWrite[NotebookStore[nb_RemoteNotebook, key_String], data_ ] := With[{},
    EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreSet", <|"Ref"->nb[[1]], "Key"->key, "Data"->Compress[data], "Promise" -> Null, "Kernel"->Internal`Kernel`Hash|>];
]

NotebookStore /: NotebookWrite[NotebookStore[keys: {__String}], data_List ] := With[{nb = EvaluationNotebook[]}, NotebookWrite[NotebookStore[nb, keys], data ] ]
NotebookStore /: NotebookWrite[NotebookStore[nb_RemoteNotebook, keys: {__String}], data_List ] := MapThread[Function[{key, d}, NotebookWrite[NotebookStore[nb, key], d ] ],  {keys, data}]

Protect[NotebookStore]

End[]
EndPackage[]