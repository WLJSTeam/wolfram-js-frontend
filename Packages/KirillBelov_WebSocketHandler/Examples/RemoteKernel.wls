#!/usr/bin/env wolframscript
(* ::Package:: *)

Get["KirillBelov`TCPServer`"]
Get["KirillBelov`WebSocketHandler`"]

tcp = TCPServer[]
tcp["CompleteHandler", "WebSocket"] = WebSocketPacketQ -> WebSocketPacketLength
tcp["MessageHandler", "WebSocket"]  = WebSocketPacketQ -> ws

ws = WebSocketHandler[]
ws["MessageHandler", "Evaluate"]  = Function[True] -> evaluate

evaluate[client_SocketObject, data_ByteArray] := 
WebSocketSend[client, data]; 

listener = SocketListen[8000, tcp@#&]
While[True, Pause[0.01]]
