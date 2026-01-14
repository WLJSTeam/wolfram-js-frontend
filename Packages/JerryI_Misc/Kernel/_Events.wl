BeginPackage["JerryI`Misc`Events`"]; 

(* 
    A kernel event system package 
    following KISS principle 

    can be extended by other packages
    for example WebObjects/Dynamics -> Slider
*)

EventObject::usage = "a representation of a simple event. can hold an extra information"

EventJoin::usage = "join sequence of many EventObjects to a new one"
EventClone::usage = "dublicate an event object keeping all handlers"

EventRemove::usage = "remove the bond from EventObject"

EventFire::usage = "manually fire an event object"

EventBind::usage = "legacy method to bind events"

EventsRack::usage = "depricated!"

EmittedEvent::usage = "internal function called by the frontend to fire an event on a kernel"
EventHandlers::usage = "internal function, which hold the binded function"

EventListener::usage = "internal command"

MiddlewareHandler::usage = "internal command"
MiddlewareListener::usage = "internals"

Assign::usage = "internal autobinding"

Begin["`Private`"]; 


EventBind[EventObject[assoc_], handler_] ^:= (EventHandlers[assoc["id"] ] = handler; EventObject[assoc]);
EventBind[id_String, handler_] := (EventHandlers[id] = handler;);

(* shotcut *)
EventObject[assoc_][handler_] := (EventHandlers[assoc["id"] ] = handler; EventObject[assoc]);

Assign[symbol_][EventObject[assoc_]] ^:= (
    EventHandlers[assoc["id"] ] = With[{s = Unevaluated[symbol]}, 
        Function[data, s = data]
    ];
    
    EventObject[assoc]
);

SetAttributes[Assign, HoldFirst]

EmittedEvent[EventObject[assoc_], data_] := EventHandlers[ assoc["id"] ][data];
EmittedEvent[EventObject[assoc_], name_String, data_] := EventHandlers[assoc["id"], name][data];

EmittedEvent[id_String, data_] := ( EventHandlers[id][data] );
EmittedEvent[id_String, name_String, data_] := ( EventHandlers[id, name][data] );

EventRemove[EventObject[assoc_]] := (With[{id = assoc["id"]}, Unset[ EventHandlers[id] ] ]);
EventRemove[id_String] := Unset[ EventHandlers[id] ];

EventRemove[EventObject[assoc_], name_String] := (With[{id = assoc["id"]}, Unset[ EventHandlers[id, name] ] ]);
EventRemove[id_String, name_String] := Unset[ EventHandlers[id, name] ];

EventClone[EventObject[assoc_]] := EventClone[assoc["id"]]
EventClone[EventObject[assoc_], name_String] := EventClone[assoc["id"], name]

EventClone[assocId_String] := (
    With[{t = EventHandlers[assocId], id = assocId, cuid = CreateUUID[]}, 
        If[Head[t] =!= EventRouter,
            (* reroute *)
            Print["reroute existing event"];
            With[{nuid = CreateUUID[]},
                If[Head[t] =!= EventHandlers,
                    EventHandlers[nuid] = EventHandlers[id];
                    EventRouter[id, "list"] = {nuid};
                ,
                    EventRouter[id, "list"] = {};
                ];    
                EventHandlers[id] = EventRouter[id];
                EventRouter[id][data_] := EmittedEvent[#, data] &/@ EventRouter[id, "list"];
            ];
        ];

        EventRouter[id, "list"] = Append[EventRouter[id, "list"], cuid];

        EventObject[<|"id"->cuid|>]
    ]
)

EventClone[assocId_String, name_String] := (
    With[{t = EventHandlers[assocId, name], id = assocId, cuid = CreateUUID[]}, 
        If[Head[t] =!= EventRouter,
            (* reroute *)
            Print["reroute existing event"];
            With[{nuid = CreateUUID[]},
                If[Head[t] =!= EventHandlers,
                    EventHandlers[nuid, name] = EventHandlers[id, name];
                    EventRouter[id, name, "list"] = {nuid};
                ,
                    EventRouter[id, name, "list"] = {};
                ];    
                EventHandlers[id, name] = EventRouter[id];
                EventRouter[id, name][data_] := EmittedEvent[#, name, data] &/@ EventRouter[id, name, "list"];
            ];
        ];

        EventRouter[id, name, "list"] = Append[EventRouter[id, name, "list"], cuid];

        EventObject[<|"id"->cuid|>]
    ]
)

EventJoin[seq__] := With[{list = List[seq], joined = CreateUUID[]},
Module[{handler, data = Empty},
    (
        If[Head[#] === EventObject,
            If[KeyExistsQ[#[[1]], "initial"],
                If[data === Empty, data = #[[1]]["initial"], data = Join[data, #[[1]]["initial"]]];
            ];
        ];
        EventHandler[EventClone[#], Function[d, EmittedEvent[joined, If[data === Empty, d, data = Join[data, d]]]]]
    ) &/@ list;

    If[data =!= Empty,
        EventObject[<|"id"->joined, "storage"->Hold[data], "initial"->data|>]
    ,
        EventObject[<|"id"->joined, "storage"->Hold[data]|>]
    ]
]] 

EventObject /: Join[evs__EventObject] := EventJoin[evs]
EventObject /: Delete[ev_EventObject] := EventRemove[ev]
EventObject /: DeleteObject[ev_EventObject] := EventRemove[ev]

EventFire[EventObject[assoc_]] := (
    EmittedEvent[assoc["id"], If[KeyExistsQ[assoc, "initial"], assoc["initial"], Empty]]
)

EventFire[EventObject[assoc_], data_] := (
    EmittedEvent[assoc["id"], data]
)

EventFire[id_String] := (
    EmittedEvent[id, Empty]
)

EventFire[id_String, data_] := (
    EmittedEvent[id, data]
)

(* an union of many events *)
EventsRack[list_] := With[{uid = CreateUUID[]},
    With[{central = Function[data, EmittedEvent[uid, data]]},
        With[{i = #["id"]}, 
            With[{handler = Function[data, central[Rule[i, data]]]},
                EventBind[#, handler] 
            ]
        ] &/@ list;
    ];
    EventObject[<|"id"->uid|>]
]

Unprotect[EventHandler]
ClearAll[EventHandler]
EventHandler[expr_, ev_List] := Module[{eventsList = {}},
    eventsList = With[{func = #[[2]], type = #[[1]], id = CreateUUID[]},
        EventBind[EventObject[<|"id"->id|>], func];
        type -> id
    ]&/@ ev;

    EventListener[expr, (Sequence@@eventsList)]
]

EventHandler[cid_String, ev_List] := Module[{eventsList = {}},
    eventsList = With[{func = #[[2]], id = cid<>"-"<>#[[1]]},
        EventBind[EventObject[<|"id"->id|>] // EventClone, func];
        EventObject[<|"id"->id|>]
    ]&/@ ev;
    eventsList
]

EventHandler[Global`CellObj[cid_String], ev_List] := EventHandler[cid, ev]

(* better to use this instead of EventBind *)
EventHandler[EventObject[assoc_Association], handler_] ^:= (
    EventHandlers[assoc["id"]] = handler;
    EventObject[assoc]
)

EventHandler[id_String, handler_] := (
    EventHandlers[id] = handler;
)



MiddlewareHandler[expr_, ev_Rule, opts___] := With[{id = CreateUUID[], type = ev[[1]], func = ev[[2]]},
    EventBind[EventObject[<|"id"->id|>], func];

    MiddlewareListener[expr, type, id, opts]
]

End[];

EndPackage[];

