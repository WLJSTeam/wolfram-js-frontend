(* ::Package:: *)

BeginPackage["KirillBelov`WebSocketHandler`Extensions`", {"KirillBelov`WebSocketHandler`", "KirillBelov`TCPServer`"}]


AddWebSocketHandler::usage = 
"AddWebSocketHandler[tp, ws] adds ws to tcp."; 


Begin["`Private`"]


AddWebSocketHandler[tcp_TCPServer, key_String: "WebSocket", ws_WebSocketHandler] := (
	tcp["CompleteHandler", key] = WebSocketPacketQ -> WebSocketPacketLength; 
	tcp["MessageHandler", key] = WebSocketPacketQ -> ws; 
);


End[]


EndPackage[]