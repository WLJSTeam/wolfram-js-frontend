(* ::Package:: *)

BeginPackage["CoffeeLiqueur`WebSocketHandler`RemoteParallelKernel`", {
	"CoffeeLiqueur`TCPServer`", 
	"CoffeeLiqueur`WebSocketHandler`", 
	"CoffeeLiqueur`WebSocketHandler`Extensions`"
}]; 


RPKStart::usage = 
"RPKStart[port] starts remote parallel kernel via WebSocket protocol."; 


RPKStop::usage = 
"RPKStop[port] stops kernel."; 


RPKReadyQ::usage = 
"RPKReadyQ[port] check that kernel is ready."; 


Begin["`Private`"]; 


RPKStart[port_Integer] := 
Module[{link}, 
	link = LinkLaunch[First[$CommandLine] <> " -wstp"]; 
	LinkRead[link];
	With[{definition = Language`ExtendedFullDefinition[createWebSocketKernel]}, 
		LinkWrite[link, Unevaluated[Function[Language`ExtendedFullDefinition[] = #][definition]]];
		TimeConstrained[
			While[!LinkReadyQ[link], Pause[0.001]]; 
			LinkRead[link]; 
			LinkWrite[link, Unevaluated[createWebSocketKernel[port]]]; 
			While[!LinkReadyQ[link], Pause[0.001]]; 
			LinkRead[link];, 
			10
		]; 

		(*Return: LinkObject*)
		$links[port] = link
	]
]; 


RPKStop[port_Integer] := 
If[KeyExistsQ[$links, port], Close[$links[port]; Delete[$links, Key[port]]]]; 


$links = <||>; 


webSocketEvaluate[client_SocketObject, message_ByteArray] := 
WebSocketSend[client, ExportByteArray[ImportByteArray[message, "WL"], "ExpressionJSON"]]; 


createWebSocketKernel[port_Integer] := 
Module[{ws, tcp}, 
	ws = WebSocketHandler[]; 
	ws["MessageHandler", "RemoteKernel"] = Function[True] -> webSocketEvaluate; 
	tcp = TCPServer[]; 
	AddWebSocketHandler[tcp, ws]; 

	(*Return: SocketListener[]*)
	With[{t = tcp}, SocketListen[port, t@#&]]
]; 

End[]; 


EndPackage[]; 
