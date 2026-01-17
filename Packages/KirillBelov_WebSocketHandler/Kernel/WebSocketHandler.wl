(* ::Package:: *)

(* ::Chapter:: *)
(*WS Handler*)


(* ::Program:: *)
(*+---------------------------------------------------+*)
(*|               WEBSSOCKET HANDLER                  |*)
(*|                                                   |*)
(*|                (reseive message)                  |*)
(*|                        |                          |*)
(*|               <check message type>                |*)
(*|              /         |          \               |*)
(*|   [handshake]       [frame]        [close frame]  |*)
(*|       |                |                 |        |*)
(*|  [send accept]     [decode]           {close}     |*)
(*|       |                |                          |*)
(*|    {to tcp}      [deserialize]                    |*)
(*|                        |                          |*)
(*|                 <select pipeline>                 |*)
(*|       /        /                 \       \        |*)
(*|     ..    [callback]         [subscribe]  ..      |*)
(*|                   \            /                  |*)
(*|                    <check type>                   |*)
(*|              null /            \ data             |*)
(*|             {next}            [serialize]         |*)
(*|                                    |              |*)
(*|                                 {to tcp}          |*)
(*+---------------------------------------------------+*)


(*::Section::Close::*)
(*Begin package*)


BeginPackage["KirillBelov`WebSocketHandler`", {"KirillBelov`Internal`", "KirillBelov`Objects`"}]; 


(*::Section::Close::*)
(*Names*)


ClearAll["`*"]; 


$CurrenctClient::usage = 
"Current client."; 


WebSocketPacketQ::usage = 
"WebSocketPacketQ[client, packet] check that packet sent via WebSocket protocol."; 


WebSocketPacketLength::usage = 
"WSLength[client, message] get expected message length."; 


WebSocketSend::uasge = 
"WebSocketSend[client, message] send message via WebSocket protocol."; 


WebSocketChannel::usage = 
"WebSocketChannel[name] multiple client connection."; 


WebSocketHandler::usage = 
"WebSocketHandler[opts] handle messages received via WebSocket protocol."; 


(*::Section::Close::*)
(*Begin private*)


Begin["`Private`"]; 


ClearAll["`*"]; 


WebSocketPacketQ[client_, message_ByteArray] := 
(frameQ[client, message] || handshakeQ[client, message]); 


WebSocketPacketLength[client_, message_ByteArray] := 
If[frameQ[client, message], 
	getFrameLength[client, message], 
	Length[message]
]; 


Options[WebSocketSend] = {
	"Serializer" -> $serializer
}


WebSocketSend[client_, message: _String | _ByteArray] := 
BinaryWrite[client, encodeFrame[message]]; 


WebSocketSend[client_, expr_, OptionsPattern[]] := 
Module[{serializer, message}, 
	serializer = OptionValue["Serializer"]; 
	message = serializer[expr]; 
	WebSocketSend[client, message]
]; 


CreateType[WebSocketChannel, init, {
	"Name", 
	"Serializer" -> $serializer, 
	"Connections"
}]; 


WebSocketChannel[name_String, clients: {___}: {}, serializer_: $serializer] := 
Module[{channel, connections}, 
	channel = WebSocketChannel["Name" -> name, "Serializer" -> serializer]; 
	connections = channel["Connections"]; 
	Map[connections["Insert", #]&, clients]; 
	
	(*Return: WebSocketChannel[]*)
	channel
]; 


WebSocketChannel /: Append[channel_WebSocketChannel, client_] := 
Module[{connections}, 
	connections = channel["Connections"]; 
	connections["Insert", client]; 

	Echo[client, "Added client:"];
	Echo[connections//Normal, "Current subscriptions:"];

	(*Return: WebSocketChannel[]*)
	channel
]; 


WebSocketChannel /: Delete[channel_WebSocketChannel, client_] := 
Module[{connections}, 
	connections = channel["Connections"]; 
	connections["Remove", client]; 

	Echo[client, "Deleted client:"];
	Echo[connections//Normal, "Current subscriptions:"];

	(*Return: WebSocketChannel[]*)
	channel
]; 


WebSocketChannel /: WebSocketSend[channel_WebSocketChannel, client_, message: _String | _ByteArray] := 
If[FailureQ[#], Delete[channel, client]]& @ WebSocketSend[client, message]; 


WebSocketChannel /: WebSocketSend[channel_WebSocketChannel, client_, expr_] := 
Module[{serializer, message}, 
	serializer = channel["Serializer"]; 
	message = serializer[expr]; 
	WebSocketSend[channel, client, message]; 
]; 


WebSocketChannel /: WebSocketSend[channel_WebSocketChannel, expr_] := 
Module[{connections}, 
	connections = channel["Connections"]; 
	Map[WebSocketSend[channel, #, expr]&, connections["Elements"]]; 
]; 


CreateType[WebSocketHandler, init, {
	"MessageHandler" -> <||>, 
	"DefaultMessageHandler" -> $defaultMessageHandler, 	
	"Deserializer" -> $deserializer, (*Input: <|.., "Data" -> ByteArray[]|>*)
	"Serializer" -> $serializer, (*Return: ByteArray[]*) 
	"Connections", 
	"Buffer"
}]; 


handler_WebSocketHandler[client_, message_ByteArray] := 
Module[{connections, deserializer, messageHandler, defaultMessageHandler, frame, buffer, data, expr, joinedMessage, extra}, 
	$CurrenctClient = client; 

	connections = handler["Connections"]; 
	deserializer = handler["Deserializer"]; 
	(* lost bytes from the last round + current message *)
	joinedMessage = Join[getRawFromLater[client], message];

	Which[
		(*Return: Null*)
		closeQ[client, joinedMessage], 
			saveRawForLater[ByteArray[{}], client]; (* flush the rest [FIXME]*)
			$connections = Delete[$connections, Key[client] ];
			connections["Remove", client];, 

		(*Return: ByteArray*)
		pingQ[client, joinedMessage], 
			saveRawForLater[ByteArray[{}], client]; (* flush the rest [FIXME]*)
			pong[client, joinedMessage], 

		(*Return: Null*)
		frameQ[client, joinedMessage], 
			{frame, extra} = decodeFrame[joinedMessage]; 
			
			(* failed to parse the header -> need more data *)
			If[FailureQ[frame],
				saveRawForLater[joinedMessage, client];
				Return[];
			];

			buffer = handler["Buffer"]; 

			If[
				frame["Fin"], 
					deserializer = handler["Deserializer"]; 
					data = getDataAndDropBuffer[buffer, client, frame]; 
					expr = deserializer[data]; 
					messageHandler = handler["MessageHandler"]; 
					defaultMessageHandler = handler["DefaultMessageHandler"]; 
					ConditionApply[messageHandler, defaultMessageHandler][client, expr];, 

				(*Else*) 
					saveFrameToBuffer[buffer, client, frame]; 
			];
			
			(* try to process the rest *)
			If[Length[extra] > 0, 
				handler[client, extra]
			]
			, 

		(*Return: _String*)
		handshakeQ[client, joinedMessage], 
			connections["Insert", client]; 
			$connections[client] = connections; 
			saveRawForLater[ByteArray[{}], client]; (* flush the rest [FIXME]*)
			handshake[client, message]
	]
]; 


WebSocketHandler /: WebSocketSend[handler_WebSocketHandler, client_, message_] := 
WebSocketSend[client, encodeFrame[handler, message]]; 


WebSocketHandler /: WebSocketChannel[handler_WebSocketHandler, name_String, clients: {___}: {}] := 
Module[{channel}, 
	channel = WebSocketChannel[name, clients]; 
	channel["Serializer"] := handler["Serializer"]; 

	(*Return: WebSocketChannel[]*)
	channel
]; 


(*::Section::Close::*)
(*Internal*)


$guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"; 


$httpEndOfHead = StringToByteArray["\r\n\r\n"]; 


$defaultMessageHandler = Close@#&; 


$deserializer = #&; 


$serializer = ExportByteArray[#, "Text"]&; 


$directory = DirectoryName[$InputFileName, 2]; 


$connections = <||>; 


WebSocketHandler /: init[handler_WebSocketHandler] := (
	handler["Connections"] = CreateDataStructure["HashSet"]; 
	handler["Buffer"] = CreateDataStructure["HashTable"]; 
);


WebSocketChannel /: init[channel_WebSocketChannel] := 
channel["Connections"] = CreateDataStructure["HashSet"]; 


getConnetionsByClient[client_] := 
(*Return: DataStructure[HashSet]*)
$connections[client]; 


handshakeQ[client_, message_ByteArray] := 
Module[{head, connections}, 
	(*Result: DataStructure[HashSet]*)
	connections = getConnetionsByClient[client]; 
	head = ByteArrayToString[BytesSplit[message, $httpEndOfHead -> 1][[1]]]; 

	(*Return: True | False*)
	(!DataStructureQ[connections] || !connections["MemberQ", client]) && 
	Length[message] != StringLength[head] && 
	StringContainsQ[head, StartOfString ~~ "GET /"] && 
	StringContainsQ[head, StartOfLine ~~ "Upgrade: websocket"]
]; 


frameQ[client_, message_ByteArray] := 
Module[{connections}, 
	(*Result: DataStructure[HashSet]*)
	connections = getConnetionsByClient[client];

	(*Return: True | False*)
	DataStructureQ[connections] && connections["MemberQ", client]
]; 


closeQ[client_, message_ByteArray] := 
Module[{connections}, 
	(*Result: DataStructure[HashSet]*)
	connections = getConnetionsByClient[client]; 

	(*Return: True | False*)
	connections["MemberQ", client] && 
	FromDigits[IntegerDigits[message[[1]], 2, 8][[2 ;; ]], 2] == 8
]; 


pingQ[client_, message_ByteArray] := 
Module[{connections}, 
	(*Result: DataStructure[HashSet]*)
	connections = getConnetionsByClient[client]; 

	connections["MemberQ", client] && 
	FromDigits[IntegerDigits[message[[1]], 2, 8][[2 ;; ]], 2] == 9
]; 


pong[client_, message_ByteArray] := 
Module[{firstByte}, 
	firstByte = IntegerDigits[message[[1]], 2, 8]; 
	firstByte[[5 ;; 8]] = {1, 0, 1, 0}; 

	(*Return: ByteArray*)
	Join[ByteArray[{FromDigits[firstByte, 2]}], message[[2 ;; ]]]
]; 


handshake[client_, message_ByteArray] := 
Module[{messageString, key, acceptKey}, 
	messageString = ByteArrayToString[message]; 
	key = StringExtract[messageString, "Sec-WebSocket-Key: " -> 2, "\r\n" -> 1]; 
	acceptKey = createAcceptKey[key]; 
	
	(*Return: ByteArray[]*)
	StringToByteArray["HTTP/1.1 101 Switching Protocols\r\n" <> 
	"connection: upgrade\r\n" <> 
	"upgrade: websocket\r\n" <> 
	"content-type: text/html;charset=UTF-8\r\n" <> 
	"sec-websocket-accept: " <> acceptKey <> "\r\n\r\n"]
]; 


createAcceptKey[key_String] := 
(*Return: _String*)
BaseEncode[Hash[key <> $guid, "SHA1", "ByteArray"], "Base64"]; 


encodeFrame[message_ByteArray] := 
Module[{byte1, fin, opcode, length, mask, lengthBytes, reserved}, 
	fin = {1}; 
	
	reserved = {0, 0, 0}; 

	opcode = IntegerDigits[1, 2, 4]; 

	byte1 = ByteArray[{FromDigits[Join[fin, reserved, opcode], 2]}]; 

	length = Length[message]; 

	Which[
		length < 126, 
			lengthBytes = ByteArray[{length}], 
		126 <= length < 2^16, 
			lengthBytes = ByteArray[Join[{126}, IntegerDigits[length, 256, 2]]], 
		2^16 <= length < 2^64, 
			lengthBytes = ByteArray[Join[{127}, IntegerDigits[length, 256, 8]]]
	]; 

	(*Return: _ByteArray*)
	ByteArray[Join[byte1, lengthBytes, message]]
]; 


encodeFrame[message_String] := 
encodeFrame[StringToByteArray[message]]; 


WebSocketHandler /: encodeFrame[handler_WebSocketHandler, expr_] := 
Module[{serializer}, 
	serializer = handler["Serializer"]; 
	
	(*Return: ByteArray[]*)
	encodeFrame[serializer[expr]]
]; 


decodeFrame[message_ByteArray] := 
Module[{header, payload, data}, 
	header = getFrameHeader[message]; 

	(* check for fragmentation of the header *)
	If[FailureQ[header],
		(*Need more bytes *)
		(*Echo["WebSocketHandler >> Need more bytes"]; *)
		Return[{$Failed, message}];
		(*Return: {$Failed, _ByteArray}*)
	];

	(* check for fragmentation of the payload *)
	If[header["PayloadPosition"][[2]] > Length[message],
		(*Need more bytes *)
		(*Echo["WebSocketHandler >> Payload is less than a buffer size"]; *)
		Return[{$Failed, message}];
		(*Return: {$Failed, _ByteArray}*)	
	];

	payload = message[[header["PayloadPosition"]]]; 
	data = If[Length[header["MaskingKey"]] == 4, ByteArray[ByteMask[header["MaskingKey"], payload]], payload]; 
	(*Return: {data_Association, extra_ByteArray}*)
	{Append[header, "Data" -> data], Drop[message, header["PayloadPosition"][[2]] ]}
]; 


getFrameLength[client_, message_ByteArray] := 
Module[{length}, 
	length = FromDigits[IntegerDigits[message[[2]], 2, 8][[2 ;; ]], 2]; 

	Which[
		length == 126, length = FromDigits[Normal[message[[3 ;; 4]]], 256] + 8, 
		length == 127, length = FromDigits[Normal[message[[3 ;; 10]]], 256] + 14, 
		True, length = length + 6
	]; 

	(*Return: _Integer*)
	length
]; 


getFrameHeader[message_ByteArray] := 
Module[{byte1, byte2, fin, opcode, mask, len, maskingKey, nextPosition, payload, data}, 
	byte1 = IntegerDigits[message[[1]], 2, 8]; 
	byte2 = IntegerDigits[message[[2]], 2, 8]; 

	fin = byte1[[1]] === 1; 
	opcode = Switch[FromDigits[byte1[[2 ;; ]], 2], 
		1, "Part", 
		2, "Text", 
		4, "Binary", 
		8, "Close"
	]; 

	mask = byte2[[1]] === 1; 

	len = FromDigits[byte2[[2 ;; ]], 2]; 

	nextPosition = 3; 

	Which[
		len == 126, len = FromDigits[Normal[message[[3 ;; 4]]], 256]; nextPosition = 5, 
		len == 127, len = FromDigits[Normal[message[[3 ;; 10]]], 256]; nextPosition = 11
	]; 

	If[mask, 
		maskingKey = message[[nextPosition ;; nextPosition + 3]]; nextPosition = nextPosition + 4, 
		maskingKey = ByteArray[{}]
	]; 

	(* if the header is split in multiple TCP packets *)
	(*Return: $Failed*)
	If[!NumberQ[len] || !ByteArrayQ[maskingKey],
		(* Echo["WebSocketHandler >> Frame header is broken!"]; *)
		(* Echo[{len, maskingKey}]; *)
		Return[$Failed];
		(*Return: $Failed*)
	];

	(*Return: _Association*)
	<|
		"Fin" -> fin, 
		"OpCode" -> opcode, 
		"Mask" -> mask, 
		"Len" -> len, 
		"MaskingKey" -> maskingKey, 
		"PayloadPosition" -> nextPosition ;; nextPosition + len - 1
	|>
]; 

bufferedRawData[_] := ByteArray[{}];

saveRawForLater[buffer_ByteArray, client_: _[uuid_] ] := bufferedRawData[uuid] = buffer;
getRawFromLater[client_: _[uuid_] ] := With[{saved = bufferedRawData[uuid]},
	bufferedRawData[uuid] = ByteArray[{}];
	saved
]

saveFrameToBuffer[buffer_DataStructure, client: _[uuid_], frame_] := 
Module[{clientBuffer}, 
	If[buffer["KeyExistsQ", uuid], 
		clientBuffer = buffer["Lookup", uuid]; 
		clientBuffer["Append", frame]; , 
	(*Else*)
		clientBuffer = CreateDataStructure["DynamicArray", {frame}]; 
		buffer["Insert", uuid -> clientBuffer]; 
	]; 
	(*Return: Null*)
]; 


getDataAndDropBuffer[buffer_DataStructure, client: _[uuid_], frame_] := 
Module[{fragments, clientBuffer}, 
	If[buffer["KeyExistsQ", uuid], 
		clientBuffer = buffer["Lookup", uuid]; 
		If[clientBuffer["Length"] > 0, 
			fragments = Append[clientBuffer["Elements"], frame][[All, "Data"]]; 
			clientBuffer["DropAll"]; 
			(*Return: ByteArray[]*)
			Apply[Join, fragments], 
		(*Else*)
			(*Return: ByteArray[]*)
			frame["Data"]
		], 
	(*Else*)
		(*Return: ByteArray[]*)
		frame["Data"]
	]
]; 


(*::Section::Close::*)
(*End private*)


End[]; 


(*::Section::Close::*)
(*End package*)


EndPackage[]; 
