BeginPackage["JerryI`Misc`Events`"]; 

(* 
    A kernel event system package 
    following KISS principle 

   can be patterns as well and delayed as well


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

Unprotect[EventHandler]
ClearAll[EventHandler]

EventHandler::usage = "EventHandler[ev_String | _EventObject, {handlers___Rule | handlers___RuleDelayed}] ev_ binds an event object represented as a string or EventObject or anything compatible with this type to a single or multiple handling functions (multiple - only if patterns do not intersect). Returns an original event-object ev"


EventListener::usage = "Listener Object"

EventPacket::usage = "just handy wrapper"

Begin["`Private`"]; 

EventObject[] := EventObject[<|"Id" -> CreateUUID[]|>]
EventObject[uid_String] := EventObject[<|"Id" -> uid|>]
EventObject[a_Association][field_] := a[field]

(* old alias *)
EventBind[any_, handler_Function] := EventHandler[any, handler]


listener[p_, list_] := With[{uid = CreateUUID[]}, With[{
    rules = Map[Function[rule, rule[[1]] -> uid ], list]
},
    EventHandler[uid, list];
    EventListener[p, rules]
] ]

EventHandler[Null, p_List] := listener[Null, p]


EventHandler[EventObject[a_Association], f_] := With[{},
    EventHandler[a["Id"], f];
    EventObject[a]
]

EventHandler[a_String, f_] := With[{},
    EventHandler[a, {_String -> f}];
    a
]

EventHandler[a_String, f_List] := With[{},
    If[!AssociationQ[EventHandlers[a] ], EventHandlers[a] = <||>];
    EventHandlers[a] = Join[EventHandlers[a], Association[f] ];
    a 
]

EventRemove[a_String, part_] := (EventHandlers[a] = KeyDrop[EventHandlers[a], part]);
EventRemove[a_String] := (EventHandlers[a] = .)

EventRemove[EventObject[a_Association] ] := EventRemove[ a["Id"] ]
EventRemove[EventObject[a_Association], t_] := EventRemove[ a["Id"], t ]

EventObject /: Delete[EventObject[a_Association], opts___] := EventRemove[EventObject[a], opts]
EventObject /: DeleteObject[EventObject[a_Association], opts___] := EventRemove[EventObject[a], opts]

EventFire[EventObject[a_Association] ] := With[{uid = a["Id"]}, 
    If[KeyExistsQ[a, "Initial"],
        EventFire[ uid, a["Initial"] ]
    ,
        EventFire[ uid, Null ]
    ];

    EventObject[a]
]

EventFire[EventObject[a_Association], data_] := With[{uid = a["Id"]}, 
    EventFire[ uid, data ]
]

EventFire[EventObject[a_Association], part_, data_] := With[{uid = a["Id"]}, 
    EventFire[ uid, part, data]
]

EventFire[uid_String, part_, data_] := EventFire[EventHandlers[uid], part, data]

EventFire[assoc_Association, part_, data_] := With[{replacements = assoc},
    (part /. Normal[replacements])[data]
]

EventFire[router_EventRouter, part_, data_] := With[{},
    EventFire[#, part, data] &/@ router[[1]]
]

EventFire[uid_String, data_] := EventFire[uid, "!_-_!", data]

EventRouter /: Append[EventRouter[data_List], uid_String] := EventRouter[Join[data, {uid}]];

EventClone[assocId_String] := (
    With[{t = EventHandlers[assocId], id = assocId, cuid = CreateUUID[]}, 
        Switch[Head[t],
            EventRouter,

            (*Print["Events >> adding new event to an existing chain"];*)
            t = Append[t, cuid];
        ,
            EventHandlers,

            (*Print["Events >> making a router from an empty event object"];*)
            t = EventRouter[{cuid}];
        ,
            Association,

            (*Print["Events >> reroute existing handlers"];*)
            With[{nid = CreateUUID[]},
                EventHandlers[nid] = t;
                EventHandlers[assocId] = EventRouter[{nid, cuid}];
            ];
        ,
            _,
            Print[StringTemplate["Events >> Internal error! Head `` is not valid"][Head[t] ] ];
            Return[$Failed];
        ];

        EventObject[<|"Id" -> cuid|>]
    ]
)

EventClone[EventObject[assoc_]] := EventObject[Join[assoc, EventClone[assoc["Id"] ][[1]] ] ]

EventJoin[seq__] := With[{list = List[seq], joined = CreateUUID[]},
Module[{data = <||>},
    With[{cloned = #},
        Switch[Head[#],
            String,
            Null;
        ,   
            EventObject,
            If[KeyExistsQ[cloned[[1]], "Initial"], With[{},
                (* check if types convertion is needed *)
                (* associations will be merged together *)
  
                If[AssociationQ[cloned[[1]]["Initial"] ], data = Join[data, cloned[[1]]["Initial"] ] ];
            ] ];
        ];
        
        With[{},
            EventHandler[cloned, {any_ :> Function[d,
                EventFire[joined, any, d]
            ]} ];
        ];
    ]&/@list;

    EventObject[<|"Id" -> joined, "Initial" -> data, "storage" -> Hold[data]|>]
] ] 

EventObject /: Join[evs__EventObject] := EventJoin[evs]


End[];

EndPackage[];

