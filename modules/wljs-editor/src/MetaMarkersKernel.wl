

BeginPackage["CoffeeLiqueur`Extensions`MetaMarkers`", {
    "CoffeeLiqueur`Extensions`Communication`",
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`",
    "JerryI`Misc`WLJS`Transport`"
}]


(* DEPRICATED !!! *)
(* DEPRICATED !!! *)
MetaMarker::usage = "depricated"
MarkerContainer::usage = "depricated"

Begin["`Private`"]

(* DEPRICATED !!! *)

notString[s_] := !StringQ[s]
MetaMarker[s_?notString] := MetaMarker[s // ToString]

(* DEPRICATED !!! *)
(* DEPRICATED !!! *)
FrontSubmit[expr_, m_MetaMarker, OptionsPattern[] ] := With[{cli = OptionValue["Window"]["Socket"]},
    If[OptionValue["Tracking"],     
        With[{uid = CreateUUID[]}, 
            If[FailureQ[WLJSTransportSend[MarkerContainer[FrontEndInstanceGroup[expr, uid], m], cli] ], $Failed,
                FrontEndInstanceGroup[uid, OptionValue["Window"] ]
            ] 
        ]
    ,
        If[FailureQ[WLJSTransportSend[MarkerContainer[expr, m], cli] ], $Failed,
            Null
        ]          
    ]
    
]

(* DEPRICATED !!! *)(* DEPRICATED !!! *)
(* DEPRICATED !!! *)(* DEPRICATED !!! *)
FrontFetchAsync[expr_, m_MetaMarker, OptionsPattern[] ] := With[{cli = OptionValue["Window"]["Socket"], format = OptionValue["Format"], event = CreateUUID[], promise = Promise[]},
    EventHandler[event, Function[payload,
        EventRemove[event];

        With[{result = Switch[format,
            "Raw",
                URLDecode[payload],
            "ExpressionJSON",
                ImportString[URLDecode[payload], "ExpressionJSON"],
            _,
                ImportString[URLDecode[payload], "JSON"]
        ]},
            If[FailureQ[result],
                EventFire[promise, Reject, result]
            ,
                EventFire[promise, Resolve, result]
            ]
        ]
    ] ];

    WLJSTransportSend[System`FSAsk[MarkerContainer[expr,m], event], cli];

    promise
]

End[]

EndPackage[]