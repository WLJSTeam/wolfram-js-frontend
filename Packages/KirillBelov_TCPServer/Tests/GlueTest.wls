<<KirillBelov`TCPServer`


tcp = TCPServer[]


tcp["CompleteHandler", "Test"] = Function[Echo[ByteArrayToString[#2], "Server Receive"]; True] -> Function[10]
tcp["MessageHandler", "Test"] = Function[True] -> Function[Echo[Pause[0.25]; ByteArrayToString[#2], "Server Handle"]; #2]


SocketListen[8080, tcp@#&]


client = SocketConnect[8080]; 


BinaryWrite[client, StringToByteArray[Echo["0123456789ABCDE", "Client Send"]]]; 


TimeConstrained[While[True, 
    Pause[0.1]; 
    If[SocketReadyQ[client], 
        Echo[ByteArrayToString[SocketReadMessage[client]], "Client Read"]
    ]
], 3]; 


BinaryWrite[client, StringToByteArray[Echo["0123456789ABCDE", "Client Send"]]]; 


TimeConstrained[While[True, 
    If[SocketReadyQ[client], 
        Echo[ByteArrayToString[SocketReadMessage[client]], "Client Read"]
    ]
], 3]; 
