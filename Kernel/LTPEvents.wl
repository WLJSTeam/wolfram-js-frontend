BeginPackage["CoffeeLiqueur`LTP`Events`", {
    "CoffeeLiqueur`Misc`Events`", "CoffeeLiqueur`LTP`", "CoffeeLiqueur`Misc`Events`Promise`"
}]

Begin["`Private`"]

LTPTransport /: EventFire[LTPTransport[cli_][event_], opts__] := LTPEvaluate[LTPTransport[cli], EventFire[event, opts] ];
LTPTransport /: EventFire[LTPTransport[cli_][p_Promise], opts__] := LTPEvaluate[LTPTransport[cli], EventFire[p // First, opts] ];


End[]
EndPackage[]