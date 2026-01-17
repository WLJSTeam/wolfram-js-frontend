BeginPackage["CoffeeLiqueur`Extensions`Notifications`", {"JerryI`Misc`Events`", "JerryI`Misc`Events`Promise`", "CoffeeLiqueur`Extensions`RemoteCells`"}]


HapticFeedback::usage = "HapticFeedback[] make a haptic feedback on MacOS devices (Desktop App only)"


Notify::usage = "Deprecated. Consider to use Echo or EchoLabel"


Begin["`Private`"]

notRule[_Rule] = False
notRule[_] = True

Unprotect[Beep]
ClearAll[Beep]
Beep[]  := EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`Beeper[], True]; 
Beep["System"] := EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`Beeper[], "System"]; 
Beep[_] := Beep[]



HapticFeedback[]  := EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`Rumble[], True]; 
HapticFeedback[_] := HapticFeedback[]


Unprotect[EchoLabel];

EchoLabel["Warning"][expr_] := (EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], "Warning", ToString[expr] ]; expr); 
EchoLabel["Error"][expr_] := (EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], "Error", ToString[expr] ]; expr) 
EchoLabel["Notification"][expr_] := (EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`NotificationMessage["Kernel"], ToString[expr] ]; expr)

EchoLabel["Spinner"][expr_] := With[{p = Unique[], uid = CreateUUID[]},
    EventFire[Internal`Kernel`CommunicationChannel, "CreateSpinner", <|
                    "UId" -> uid,
                    "Kernel"->Internal`Kernel`Hash,
                    "Topic"->"Kernel",
                    "Data"->ToString[expr]
    |>];

    p["Properties"] = {"Cancel"};
    p["Cancel"] := (EventFire[Internal`Kernel`CommunicationChannel, "RemoveSpinner", uid ]; ClearAll[p]);

    p /: Delete[p] := (EventFire[Internal`Kernel`CommunicationChannel, "RemoveSpinner", uid ]; ClearAll[p]);

    p
]

EchoLabel["ProgressBar"][expr_] := With[{p = Unique[], uid = CreateUUID[]},
    EventFire[Internal`Kernel`CommunicationChannel, "CreateProgressBar", <|
                    "UId" -> uid,
                    "Kernel"->Internal`Kernel`Hash,
                    "Topic"->"Kernel",
                    "Data"->ToString[expr]
    |>];

    p["Properties"] = {"Cancel", "Set", "SetMessage"};
    p["Cancel"] := (EventFire[Internal`Kernel`CommunicationChannel, "RemoveProgressBar", uid ]; ClearAll[p]);
    p["Set", n_Real | n_Integer] := (EventFire[Internal`Kernel`CommunicationChannel, "SetProgressBar", <|
                    "UId" -> uid,
                    "Kernel"->Internal`Kernel`Hash,
                    "Bar"->n
    |> ]; n);

    p["SetMessage", n_String] := (EventFire[Internal`Kernel`CommunicationChannel, "SetProgressBarMessage", <|
                    "UId" -> uid,
                    "Kernel"->Internal`Kernel`Hash,
                    "Message"->n
    |> ]; n);    

    p /: Delete[p] := (EventFire[Internal`Kernel`CommunicationChannel, "RemoveProgressBar", uid ]; ClearAll[p]);

    p
]

Protect[EchoLabel];


(* LEGACY!!! Only for the compatibillity with outdated modules *)
(* LEGACY!!! Only for the compatibillity with outdated modules *)
(* LEGACY!!! Only for the compatibillity with outdated modules *)
(* LEGACY!!! Only for the compatibillity with outdated modules *)

Notify[template_String, args__?notRule, OptionsPattern[] ] := With[{
    message = StringTemplate[template][args]
},
    EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`NotificationMessage[OptionValue["Topic"] ], message]; 
]

Notify[template_String, OptionsPattern[] ] := With[{
    message = template
},
    Switch[OptionValue["Type"],
        "Spinner",
            With[{p = Unique["spinner"], uid = CreateUUID[]},
                EventFire[Internal`Kernel`CommunicationChannel, "CreateSpinner", <|
                    "UId" -> uid,
                    "Kernel"->Internal`Kernel`Hash,
                    "Topic"->OptionValue["Topic"],
                    "Data"->message
                |>];

                p /: Delete[p] := (EventFire[Internal`Kernel`CommunicationChannel, "RemoveSpinner", uid ]; ClearAll[p]);

                p
            ]
        ,
        
        "Warning",
            EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], "Warning", message];
        ,

        _,
            EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`NotificationMessage[OptionValue["Topic"] ], message];
            Null
    ]
    
]

Notify[template_, OptionsPattern[] ] := With[{
    message = ToString[template]
},
    EventFire[Internal`Kernel`Stdout[ Internal`Kernel`Hash ], Notifications`NotificationMessage[OptionValue["Topic"] ], message]; 
]


Options[Notify] = {"Topic" -> "Kernel", "Type"->"Message"}

End[]
EndPackage[]
