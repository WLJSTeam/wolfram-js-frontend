(* ::Package:: *)

(* ::Chapter:: *)
(*CSocketListener*)


(* ::Section:: *)
(*Begin package*)


BeginPackage["KirillBelov`CSockets`"]; 

Needs @ If[$OperatingSystem === "Windows",  
	"KirillBelov`CSockets`Interface`Windows`", 
	"KirillBelov`CSockets`Interface`Unix`"
];

(* ::Section:: *)
(*Names*)


CSocketObject::usage = 
"CSocketObject[socketId] socket representation."; 


CSocketOpen::usage = 
"CSocketOpen[port] returns new server socket."; 


CSocketConnect::usage = 
"CSocketConnect[host, port] connect to socket"; 


CSocketListener::usage = 
"CSocketListener[assoc] listener object."; 


(* ::Section:: *)
(*Private context*)


Begin["`Private`"]; 


(* ::Section:: *)
(*Implementation*)


CSocketObject[socketId_Integer]["DestinationPort"] := 
socketPort[socketId]; 


CSocketOpen[host_String: "localhost", port_Integer] := 
CSocketObject[socketOpen[host, ToString[port]]]; 


CSocketOpen[address_String ] /; 
StringMatchQ[address, __ ~~ ":" ~~ NumberString] := 
CSocketObject[Apply[socketOpen, Join[StringSplit[address, ":"], {}] ] ]; 



CSocketConnect[host_String: "localhost", port_Integer] := 
CSocketObject[socketConnect[host, ToString[port]]]; 

CSocketObject /: SocketConnect[CSocketObject[socketId_] ] := CSocketObject[ socketConnectInternal[socketId] ]; 


CSocketConnect[address_String] /; 
StringMatchQ[address, __ ~~ ":" ~~ NumberString] := 
CSocketObject[Apply[socketConnect, StringSplit[address, ":"]]]; 


CSocketObject /: BinaryWrite[CSocketObject[socketId_Integer], data_ByteArray] := With[{result = socketBinaryWrite[socketId, data, Length[data], $bufferSize]},
	If[result < 0,  $Failed, result]
]


CSocketObject /: BinaryWrite[CSocketObject[socketId_Integer], data_List] := With[{result = socketBinaryWrite[socketId, ByteArray[data], Length[data], $bufferSize]},
	If[result < 0,  $Failed, result]
]


CSocketObject /: WriteString[CSocketObject[socketId_Integer], data_String] := With[{result = socketWriteString[socketId, data, StringLength[data], $bufferSize]},
	If[result < 0,  $Failed, result]
]


CSocketObject /: SocketReadMessage[CSocketObject[socketId_Integer], bufferSize_Integer: $bufferSize] := 
socketReadMessage[socketId, bufferSize]; 


CSocketObject /: SocketReadyQ[CSocketObject[socketId_Integer]] := 
socketReadyQ[socketId]; 


CSocketObject /: Close[CSocketObject[socketId_Integer]] := 
socketClose[socketId]; 

StandardSocketEventsHandler = Echo[StringTemplate["`` was ``"][#2, #1] ]&;

CSocketObject /: SocketListen[socket: CSocketObject[socketId_Integer], handler_, OptionsPattern[{SocketListen, "BufferSize" -> $bufferSize, "SocketEventsHandler" -> StandardSocketEventsHandler}]] := 
With[{messager = OptionValue["SocketEventsHandler"]},
	Module[{task}, 
		task = createAsynchronousTask[socketId, 
			(With[{p = toPacket[##]}, p /. {a_Association :> handler[a], b_List :> (messager@@b)} ] ) &
		, "BufferSize" -> OptionValue["BufferSize"] ]; 

		CSocketListener[<|
			"Socket" -> socket, 
			"Host" -> socket["DestinationHostname"], 
			"Port" -> socket["DestinationPort"], 
			"Handler" -> handler, 
			"TaskId" -> task[[2]], 
			"Task" -> task
		|>]
	]; 
];


CSocketListener /: DeleteObject[CSocketListener[assoc_Association]] := 
socketListenerTaskRemove[assoc["TaskId"]]; 


(* ::Section:: *)
(*Internal*)

$bufferSize = 8192; 

toPacket[task_, "Received", {serverId_, clientId_, data_}] :=
	<|
		"Socket" -> CSocketObject[serverId], 
		"SourceSocket" -> CSocketObject[clientId], 
		"DataByteArray" -> ByteArray[data]
	|>

toPacket[task_, any_String, {serverId_, clientId_, data_}] := {any, CSocketObject[clientId]}


(* ::Section:: *)
(*End private context*)


End[]; 


(* ::Section:: *)
(*End package*)


EndPackage[]; 
