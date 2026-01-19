BeginPackage["CoffeeLiqueur`Misc`Async`", {"CoffeeLiqueur`Misc`Events`", "CoffeeLiqueur`Misc`Events`Promise`"}]; 

SetTimeout::usage = "SetTimeout[expr, milliseconds_Number] async scheldued task once after period"
SetInterval::usage = "SetInterval[expr, milliseconds_Number] async scheldued task every period"
CancelTimeout::usage = "CancelTimeout[task] cancel the timer"
CancelInterval::usage = "CancelInterval[task] cancel the timer"


AsyncFunction::usage = "AsyncFunction[args, body] is a pure (or \"anonymous\") async function. Returns Promise"
Await::usage = "Await[expr] is used in AsyncFunction to pause the execution until expr is resolved"

PauseAsync::usage = "Async version of Pause[n], that returns promise"

TableAsync::usage = "TableAsync[expr, {i,1,5}}] where expr can be async expression  and the interator syntax is the same as for Table. Returns Promise with list";
DoAsync::usage = "DoAsync[expr, {i,1,5}}] where expr can be async expression and the interator syntax is the same as for Do. Returns Promise";

MicrotasksRun::usage = "MicrotasksRun[] runs microtasks";
MicrotaskSubmit::usage = "MicrotaskSubmit[expr_] submit held expression to a microtask loop run by MicrotasksRun"

Begin["`Private`"]; 


SetTimeout[expr_, timeout_] := SessionSubmit[ScheduledTask[expr, {Quantity[timeout/1000, "Seconds"]}] ]
SetTimeout[expr_, timeout_Quantity] := SessionSubmit[ScheduledTask[expr, {timeout}] ]
CancelTimeout[t_TaskObject] := TaskRemove[t]

SetInterval[expr_, timeout_] := SessionSubmit[ScheduledTask[expr, Quantity[timeout/1000, "Seconds"] ] ]
SetInterval[expr_, timeout_Quantity] := SessionSubmit[ScheduledTask[expr, timeout ] ]
CancelInterval[t_TaskObject] := TaskRemove[t]

SetAttributes[SetTimeout, HoldFirst]
SetAttributes[SetInterval, HoldFirst]


asyncTransform;
SetAttributes[asyncTransform, HoldFirst]

asyncReturn;

asyncTransform[a_] := a

asyncTransform[CompoundExpression[b_]] := asyncTransform[b]

asyncTransform[Await[a_]] := asyncReturn[a]

asyncTransform[Module[vars_, body_]] := Module[vars, asyncTransform[body]]

asyncTransform[With[vars_, body_]] := With[vars, asyncTransform[body]]

asyncTransform[If[cond_, a_]] := asyncTransform[If[cond, a, Null]]

asyncTransform[If[cond_, a_, b_]] := With[{condition = asyncTransform[cond]},
  If[MatchQ[condition, _asyncReturn],
    Module[{cp = Promise[]},
      Then[Extract[cp, 1], Function[result,
        EventFire[cp, Resolve, asyncTransform[If[result, a, b]]];
      ], Function[null0,
        EventFire[cp, Reject, $Failed];
      ]];

      asyncReturn[cp]
    ]
  ,
    If[TrueQ[condition],
      With[{ares = asyncTransform[a]},
        If[MatchQ[ares, _asyncReturn],
          Module[{cap = Promise[]},
          
            Then[Extract[ares, 1], Function[result,
              EventFire[cap, Resolve, result];
            ], Function[null0,
              EventFire[cap, Reject, $Failed];
            ]];
            
            asyncReturn[cap]
          ]
        ,
          ares
        ]
      ]
    ,
      With[{bres = asyncTransform[b]},
        If[MatchQ[bres, _asyncReturn],
          Module[{cbp = Promise[]},
          
            Then[Extract[bres, 1], Function[result,
              EventFire[cbp, Resolve, result];
            ], Function[null0,
              EventFire[cbp, Reject, $Failed];
            ]];
            
            asyncReturn[cbp]
          ]
        ,
          bres
        ]
      ]    
    ]
  ]
]

SetAttributes[TableAsync, HoldAll]
SetAttributes[DoAsync, HoldAll]

TableAsync[expr_, {max_Integer}] := Module[{iterator = 1}, TableAsync[expr, {iterator, 1, max, 1}] ]
TableAsync[expr_, {iterator_Symbol, max_Integer}] := TableAsync[expr, {iterator, 1, max, 1}]
TableAsync[expr_, {iterator_Symbol, min_?NumberQ, max_?NumberQ}] := TableAsync[expr, {iterator, min, max, 1}]
TableAsync[expr_, {iterator_Symbol, min_?NumberQ, max_?NumberQ, step_?NumberQ}] :=  With[{range = Range[min, max, step]}, TableAsync[expr, {iterator, range}] ]
TableAsync[expr_, {iterator_Symbol, range_List}] := Module[{results = range}, With[{
  p = Promise[],
  wrapperFunction = AsyncFunction[iterator, 
    expr
  ]
},
  applySyncCollect[results, range, wrapperFunction, 0, Length[range], Function[Null,
    EventFire[p, Resolve, results];
  ] ]; 

  p
] ]

DoAsync[expr_, {max_Integer}] := Module[{iterator = 1}, DoAsync[expr, {iterator, 1, max, 1}] ]
DoAsync[expr_, {iterator_Symbol, max_Integer}] := DoAsync[expr, {iterator, 1, max, 1}]
DoAsync[expr_, {iterator_Symbol, min_?NumberQ, max_?NumberQ}] := DoAsync[expr, {iterator, min, max, 1}]
DoAsync[expr_, {iterator_Symbol, min_?NumberQ, max_?NumberQ, step_?NumberQ}] :=  With[{range = Range[min, max, step]}, DoAsync[expr, {iterator, range}] ]
DoAsync[expr_, {iterator_Symbol, range_List}] := With[{
  p = Promise[],
  wrapperFunction = AsyncFunction[iterator,  
    expr
  ] 
},
  applySync[range, wrapperFunction, 0, Length[range], Function[Null,
    EventFire[p, Resolve, Null];
  ] ]; 

  p
] 

applySyncCollect[resultArray_, array_, f_, length_, length_, cbk_] := cbk[resultArray];

applySyncCollect[resultArray_, array_, f_, index_, length_, cbk_] := With[{r = f[array[[index+1]]]},

  If[PromiseQ[r],
    Then[r, Function[resolved, 
      resultArray[[index+1]] = resolved;
      applySyncCollect[resultArray, array, f, index+1, length, cbk];
    ], Function[rejected, 
      resultArray[[index+1]] = $Failed;
      applySyncCollect[resultArray, array, f, index+1, length, cbk];
    ] ]
  ,
    resultArray[[index+1]] = r;

    applySyncCollect[resultArray, array, f, index+1, length, cbk];
  ];
]

SetAttributes[applySyncCollect, HoldFirst]

applySync[array_, f_, length_, length_, cbk_] := cbk[resultArray];

applySync[array_, f_, index_, length_, cbk_] := With[{r = f[array[[index+1]]]},
  If[PromiseQ[r],
    Then[r, Function[resolved, 
      applySync[array, f, index+1, length, cbk];
    ], Function[rejected, 
      applySync[array, f, index+1, length, cbk];
    ] ]
  ,
    applySync[array, f, index+1, length, cbk];
  ];
]


asyncTransform[Set[a_, b_]] := With[{res = asyncTransform[b]},
  If[MatchQ[res, _asyncReturn],
    Module[{p5 = Promise[]},
      Then[Extract[res, 1], Function[resolved,
        EventFire[p5, Resolve, Set[a, resolved] ];
      ], Function[null0,
        EventFire[p5, Reject, $Failed];
      ] ];
      
      asyncReturn[p5]
    ]
  ,
    Set[a, res]
  ]
]

asyncTransform[CompoundExpression[a_, b__]] := With[{first = asyncTransform[a]},
  If[MatchQ[first, _asyncReturn],
    Module[{p = Promise[]},
      Then[Extract[first, 1], Function[null0,
        With[{rest = asyncTransform[CompoundExpression[b] ]},
          If[MatchQ[rest, _asyncReturn],
            Then[Extract[rest, 1], Function[result,
              EventFire[p, Resolve, result];
            ], Function[null1,
              EventFire[p, Reject, $Failed];
            ] ]
          ,
            EventFire[p, Resolve, rest];
          ];
        ];
      ], Function[null2,
            EventFire[p, Reject, $Failed];
      ] ];

      asyncReturn[p]
    ]
  ,
    asyncTransform[CompoundExpression[b] ]
  ]
]

AsyncFunction[vars_, body_] := Function[vars, 
  With[{return = asyncTransform[body]},
    If[MatchQ[return, _asyncReturn],
      Module[{mainPromise = Promise[]},
        Then[Extract[return, 1], Function[result,
          EventFire[mainPromise, Resolve, result];
        ], Function[null0,
          EventFire[mainPromise, Reject, $Failed];
        ] ];
        
        mainPromise
      ]
    ,
      return
    ]
  ]
]

SetAttributes[AsyncFunction, HoldAll]

PauseAsync[n_Real | n_Integer] := With[{p = Promise[]}, 
    SessionSubmit[ScheduledTask[EventFire[p, Resolve, True];, {Quantity[n, "Seconds"]}] ];
    p
]



MicrotasksRun[] := Module[{},
    If[!microtasksQ, Return[] ];
    If[Keys[tasks] === {}, microtasksQ = False,
        With[{task = tasks[#]},
            Module[{}, task["Expr"] ]; 
            If[!task["Continuous"], tasks[#] = .; ];
        ] &/@ Keys[tasks];
    ];
]

MicrotaskSubmit[expr_, OptionsPattern[] ] := With[{uid = CreateUUID[] },
    tasks[ uid ] = <|"Expr" :> expr, "Continuous" -> OptionValue["Continuous"]|>;
    microtasksQ = True;
    Microtask[uid]
]

Microtask /: Delete[Microtask[uid_String] ] := tasks[uid] = .;

SetAttributes[MicrotaskSubmit, HoldFirst]

Options[MicrotaskSubmit] = {"Continuous" -> False}

tasks = <||>
microtasksQ = True

End[];

EndPackage[];

