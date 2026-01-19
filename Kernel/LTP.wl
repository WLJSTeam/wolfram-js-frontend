BeginPackage["CoffeeLiqueur`LTP`"]

LTPQ::usage = ""
LTPLength::usage = ""
LTPHandler::usage = ""

LTPTransport::usage = ""

LTPEvaluate::usage = ""

Begin["`Private`"]

signature = StringToByteArray["LTP"];

LTPQ[client_, message_ByteArray] := (
    message[[1 ;; 3]] === signature
)

LTPLength[client_, message_ByteArray] := (
    First[ImportByteArray[message[[4 ;; 7]], "UnsignedInteger32"]] + 4 + 3
)

LTPHandler[client_, message_ByteArray] := Block[{Global`$LTPClient = client},
    ReleaseHold[ BinaryDeserialize[message[[8 ;; ]] ] ];
]

LTPTransport /: WriteString[s_LTPTransport, message_String] := BinaryWrite[s, StringToByteArray[message] ]
LTPTransport /: BinaryWrite[LTPTransport[client_], message_ByteArray] := With[{length = Length[message]},
    BinaryWrite[client, Join[signature, ExportByteArray[length, "UnsignedInteger32"], message]];
]

LTPEvaluate[l_LTPTransport, expr_] := BinaryWrite[l, BinarySerialize[Hold[expr]]]
SetAttributes[LTPEvaluate, HoldRest]

End[]
EndPackage[]