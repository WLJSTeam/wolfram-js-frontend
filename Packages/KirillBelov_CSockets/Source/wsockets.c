#pragma region header 

#undef UNICODE

#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #define SLEEP Sleep
    #define ms 1
    #define ISVALIDSOCKET(s) ((s) != INVALID_SOCKET)
    #define CLOSESOCKET(s) closesocket(s)
    #define GETSOCKETERRNO() (WSAGetLastError())
    #pragma comment (lib, "Ws2_32.lib")
#else
    #include <string.h>
    #include <sys/types.h>
    #include <sys/socket.h>
    #include <netinet/in.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <unistd.h>
    #include <errno.h>
    #include <fcntl.h>
    #include <wchar.h>
    #include <netinet/tcp.h>
    #include <sys/select.h>
    #define INVALID_SOCKET -1
    #define NO_ERROR 0
    #define SOCKET_ERROR -1
    #define ZeroMemory(Destination,Length) memset((Destination),0,(Length))
    #define SLEEP usleep
    #define ms 1000
    inline void nopp() {}
    #define SOCKET int
    #define ISVALIDSOCKET(s) ((s) >= 0)
    #define CLOSESOCKET(s) close(s)
    #define GETSOCKETERRNO() (errno)
    #define BYTE uint8_t
    #define BOOL int
#endif

#include <stdio.h>
#include <stdlib.h>

#include "WolframLibrary.h"
#include "WolframIOLibraryFunctions.h"
#include "WolframNumericArrayLibrary.h"

volatile int emergencyExit = 0;

#pragma endregion

#pragma region initialization 

DLLEXPORT mint WolframLibrary_getVersion() {
    //printf("[WolframLibrary_getVersion]\r\nlibrary version: %d\r\n\r\n", WolframLibraryVersion);
    return WolframLibraryVersion;
}

DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
    #ifdef _WIN32
        int iResult; 
        WSADATA wsaData; 

        iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
        if (iResult != 0) {
            return LIBRARY_FUNCTION_ERROR;
        }
    #endif

    //printf("[WolframLibrary_initialize]\r\ninitialized\r\n\r\n"); 
    return LIBRARY_NO_ERROR; 
}

DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData) { 
    #ifdef _WIN32
        WSACleanup(); 
    #endif 
    emergencyExit = 1;
    SLEEP(1000 * ms);
    //printf("[WolframLibrary_uninitialize]\r\nuninitialized\r\n\r\n"); 

    return; 
}

#pragma endregion

#pragma region internal

typedef struct Server_st {
    SOCKET listenSocket;
    size_t clientsLength;
    size_t clientsLengthMax;
    size_t clientsLengthInvalid;
    SOCKET *clients;
    size_t bufferSize;
    BYTE *buffer;
}* Server;

void addClient(Server server, SOCKET client){
    server->clients[server->clientsLength] = client; 
    server->clientsLength++; 
    
    if (server->clientsLength == server->clientsLengthMax){
        server->clientsLengthMax *= 2; 
        server->clients = realloc(server->clients, server->clientsLengthMax * sizeof(SOCKET));
    }
}

void removeInvalidClients(Server server){
    size_t j = 0; 
    for (size_t i = 0; i < server->clientsLength; i++){
        if (server->clients[i] > 0) {
            server->clients[j] = server->clients[i]; 
            j++; 
        }
    }
    
    server->clientsLength = j; 
    while ((2 * server->clientsLength < server->clientsLengthMax) && server->clientsLengthMax > 1) {
        server->clientsLengthMax = server->clientsLengthMax / 2;
        server->clients = realloc(server->clients, sizeof(SOCKET) * server->clientsLengthMax);
    }
}

typedef struct SocketListenerTaskArgs_st {
    WolframLibraryData libData; 
    Server server;
}* SocketListenerTaskArgs; 

int socketWrite(SOCKET socketId, BYTE *data, int dataLength, int bufferSize){ 
    int iResult; 
    int writeLength; 
    char *buffer; 
    int errno;   
    SOCKET currentSoketIdBackup; 
    int timeoutMult = 2; 
 
    fd_set set;
    struct timeval socktimeout; 
    socktimeout.tv_sec = 6; 
    socktimeout.tv_usec = 0; 

    int rv; 
    FD_ZERO(&set);
    FD_SET(socketId, &set);

    //printf("[socketWrite]\n\n");

    for (int i = 0; i < dataLength; i += bufferSize) { 
        buffer = (char*)&data[i];  
        writeLength = dataLength - i > bufferSize ? bufferSize : dataLength - i;  

        if (select(socketId+1, NULL, &set, NULL, &socktimeout) == 1) {
            iResult = send(socketId, buffer, writeLength, 0); 
            if (iResult == SOCKET_ERROR) { 
                errno = GETSOCKETERRNO();  
                if (errno == 10035 || errno == 35) { 
                    SLEEP(timeoutMult * ms); 
                    i -= bufferSize; 
                    timeoutMult *= 2; 
                    if (timeoutMult > 1000) { 
                        return SOCKET_ERROR; 
                    } 
                } else { 
                    return SOCKET_ERROR; 
                } 
            } else { 
                timeoutMult = 2; 
            }
        } else {
            SLEEP(timeoutMult * ms); 
            i -= bufferSize; 
            timeoutMult *= 2; 
            if (timeoutMult > 1000) { 
                printf("[socketWrite]\n\ttimeout error!\n\n");
                return SOCKET_ERROR; 
            } 
        }
    } 
 
    return dataLength; 
}

MNumericArray createByteArray(WolframLibraryData libData, BYTE *data, const mint dataLength){
    MNumericArray nArray;
    libData->numericarrayLibraryFunctions->MNumericArray_new(MNumericArray_Type_UBit8, 1, &dataLength, &nArray);
    memcpy((uint8_t*) libData->numericarrayLibraryFunctions->MNumericArray_getData(nArray), data, dataLength);
    return nArray;
}

#pragma endregion

#pragma region socketOpen[host_String, port_String]: socketId_Integer 

DLLEXPORT int socketOpen(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    char* host = MArgument_getUTF8String(Args[0]);
    char* port = MArgument_getUTF8String(Args[1]);

    int iResult; 
    SOCKET listenSocket = INVALID_SOCKET; 
    struct addrinfo hints; 
    struct addrinfo *address = NULL; 
    int iMode = 1;
    int buffSize = 1048576 * 16;

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;

    iResult = getaddrinfo(host, port, &hints, &address);
    if (iResult != 0) {
        printf("[socketOpen->ERROR]\n\tgetaddrinfo() for port = %d returns error = %d\n\n", port, GETSOCKETERRNO()); 
        return LIBRARY_FUNCTION_ERROR;
    }

    listenSocket = socket(address->ai_family, address->ai_socktype, address->ai_protocol);
    if (!ISVALIDSOCKET(listenSocket)) {
        printf("[socketOpen->ERROR]\n\tsocket() for port = %d returns error = %d\n\n", port, GETSOCKETERRNO()); 
        freeaddrinfo(address);
        return LIBRARY_FUNCTION_ERROR;
    }

    int iModeNoDelay = 0; 

    iResult = setsockopt(listenSocket, IPPROTO_TCP, TCP_NODELAY, (const char*)&iModeNoDelay, sizeof(iModeNoDelay)); 
    if (iResult == SOCKET_ERROR) {
        printf("[socketOpen->ERROR]\n\tsetsockopt(TCP_NODELAY) for port = %d returns error = %d\n\n", port, GETSOCKETERRNO()); 
        CLOSESOCKET(listenSocket);
        return LIBRARY_FUNCTION_ERROR;
    }

    iResult = setsockopt(listenSocket, SOL_SOCKET, SO_KEEPALIVE, (const char*)&iMode, sizeof(iMode)); 
    if (iResult == SOCKET_ERROR) {
        printf("[socketOpen->ERROR]\n\tsetsockopt(SO_KEEPALIVE) for port = %d returns error = %d\n\n", port, GETSOCKETERRNO()); 
        CLOSESOCKET(listenSocket);
        return LIBRARY_FUNCTION_ERROR;
    }

    iResult = setsockopt(listenSocket, SOL_SOCKET, SO_RCVBUF, (const char*)&buffSize, sizeof(buffSize)); 
    if (iResult == SOCKET_ERROR) {
        printf("[socketOpen->ERROR]\n\tsetsockopt(SO_RCVBUF) for port = %d returns error = %d\n\n", port, GETSOCKETERRNO()); 
        CLOSESOCKET(listenSocket);
        return LIBRARY_FUNCTION_ERROR;
    }

    iResult = setsockopt(listenSocket, SOL_SOCKET, SO_SNDBUF, (const char*)&buffSize, sizeof(buffSize)); 
    if (iResult == SOCKET_ERROR) {
        printf("[socketOpen->ERROR]\n\tsetsockopt(SO_SNDBUF) for port = %d returns error = %d\n\n", port, GETSOCKETERRNO()); 
        CLOSESOCKET(listenSocket);
        return LIBRARY_FUNCTION_ERROR;
    }

    iResult = bind(listenSocket, address->ai_addr, (int)address->ai_addrlen);
    if (iResult == SOCKET_ERROR) {
        printf("[socketOpen->ERROR]\n\tbind() for port = %d returns error = %d\n\n", port, GETSOCKETERRNO());
        CLOSESOCKET(listenSocket);
        return LIBRARY_FUNCTION_ERROR;
    }

    iResult = listen(listenSocket, SOMAXCONN);
    if (iResult == SOCKET_ERROR) {
        printf("[socketOpen->ERROR]\n\tblisten() for port = %d returns error = %d\n\n", port, GETSOCKETERRNO());
        CLOSESOCKET(listenSocket);
        return LIBRARY_FUNCTION_ERROR;
    }

    #ifdef _WIN32 
    iResult = ioctlsocket(listenSocket, FIONBIO, &iMode); 
    #else
    int flags = fcntl(listenSocket, F_GETFL, 0); 
    flags |= O_NONBLOCK;
    flags |= O_ASYNC; 
    iResult = fcntl(listenSocket, F_SETFL, flags, &iMode); 
    #endif
    if (iResult != NO_ERROR) {
        printf("[socketOpen->ERROR]\n\tioctlsocket(FIONBIO) for port = %d returns error = %d\n\n", port, GETSOCKETERRNO());
    }

    freeaddrinfo(address);
    libData->UTF8String_disown(host); 
    libData->UTF8String_disown(port); 

    MArgument_setInteger(Res, listenSocket);
    return LIBRARY_NO_ERROR; 
}

#pragma endregion

#pragma region socketClose[socketId_Integer]: socketId_Integer 

DLLEXPORT int socketClose(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    SOCKET socketId = MArgument_getInteger(Args[0]);
    //printf("[socketClose]\n\tid: %d\n\n", socketId);
    MArgument_setInteger(Res, CLOSESOCKET(socketId));
    return LIBRARY_NO_ERROR; 
}

#pragma endregion

#pragma region internalClosingStateBroadcast

void broadcastState(int state, SOCKET client, int taskId, WolframLibraryData libData) {
    DataStore ds = libData->ioLibraryFunctions->createDataStore();
    libData->ioLibraryFunctions->DataStore_addInteger(ds, 0);
    libData->ioLibraryFunctions->DataStore_addInteger(ds, client);
    libData->ioLibraryFunctions->DataStore_addInteger(ds, 0);
    libData->ioLibraryFunctions->raiseAsyncEvent(taskId, "Closed", ds);    
}

#pragma endregion

#pragma region socketListen[socketid_Integer, bufferSize_Integer]: taskId_Integer 

static void socketListenerTask(mint taskId, void* vtarg)
{
    SocketListenerTaskArgs targ = (SocketListenerTaskArgs)vtarg;
    Server server = targ->server;
	WolframLibraryData libData = targ->libData;

    int iResult;
    SOCKET clientSocket = INVALID_SOCKET;
    char *buffer = (char*)malloc(server->bufferSize * sizeof(char));
    mint dims[1];
    MNumericArray data;
	DataStore ds;

    time_t readTime = time(NULL); 
    BOOL sleepMode = True;
    
	while(libData->ioLibraryFunctions->asynchronousTaskAliveQ(taskId) && emergencyExit == 0)
	{
        if (sleepMode){
            SLEEP(10 * ms);
            removeInvalidClients(server);
        }

        clientSocket = accept(server->listenSocket, NULL, NULL); 
        if (ISVALIDSOCKET(clientSocket)) {
            addClient(server, clientSocket);
            sleepMode = False; 
        }

        sleepMode = True; 
        for (int i = 0; i < server->clientsLength; i++) {
            if (server->clients[i] != INVALID_SOCKET) {
                iResult = recv(server->clients[i], buffer, server->bufferSize, 0); 
                if (iResult > 0) {
                    sleepMode *= False; 
                    dims[0] = iResult;
                    libData->numericarrayLibraryFunctions->MNumericArray_new(MNumericArray_Type_UBit8, 1, dims, &data); 
                    memcpy(libData->numericarrayLibraryFunctions->MNumericArray_getData(data), buffer, iResult);
                    ds = libData->ioLibraryFunctions->createDataStore();
                    libData->ioLibraryFunctions->DataStore_addInteger(ds, server->listenSocket);
                    libData->ioLibraryFunctions->DataStore_addInteger(ds, server->clients[i]);
                    libData->ioLibraryFunctions->DataStore_addMNumericArray(ds, data);
                    libData->ioLibraryFunctions->raiseAsyncEvent(taskId, "Received", ds);
                } else if (iResult == 0) {
                    broadcastState(INVALID_SOCKET, server->clients[i], taskId, libData);
                    server->clients[i] = INVALID_SOCKET;
                    
                }
            }
        }
	}

    for (int i = 0; i < server->clientsLength; i++) {
        broadcastState(INVALID_SOCKET, server->clients[i], taskId, libData);
        CLOSESOCKET(server->clients[i]);
    }

    free(targ); 
    free(server->clients);
    free(buffer);
}

DLLEXPORT int socketListen(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    SOCKET listenSocket = MArgument_getInteger(Args[0]);
    int bufferSize = MArgument_getInteger(Args[1]);
    
    mint taskId;
    SOCKET *clients = (SOCKET*)malloc(4 * sizeof(SOCKET));
    Server server = (Server)malloc(sizeof(struct Server_st));

    server->listenSocket=listenSocket;
    server->clients=clients;
    server->clientsLength=0;
    server->clientsLengthMax=4;
    server->bufferSize=bufferSize;

    SocketListenerTaskArgs threadArg = (SocketListenerTaskArgs)malloc(sizeof(struct SocketListenerTaskArgs_st));
    threadArg->libData=libData; 
    threadArg->server=server; 
    taskId = libData->ioLibraryFunctions->createAsynchronousTaskWithThread(socketListenerTask, threadArg);

    MArgument_setInteger(Res, taskId); 
    return LIBRARY_NO_ERROR; 
}

#pragma endregion

#pragma region socketListenerTaskRemove[taskId_Integer]: taskId_Integer 

DLLEXPORT int socketListenerTaskRemove(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    mint taskId = MArgument_getInteger(Args[0]);
    MArgument_setInteger(Res, libData->ioLibraryFunctions->removeAsynchronousTask(taskId));
    return LIBRARY_NO_ERROR;
}

#pragma endregion

#pragma region socketConnect[host_String, port_String]: socketId_Integer 

DLLEXPORT int socketConnect(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    char *host = MArgument_getUTF8String(Args[0]);
    char *port = MArgument_getUTF8String(Args[1]);

    int iResult; 
    int iMode = 1; 
    SOCKET connectSocket = INVALID_SOCKET; 
    struct addrinfo *address = NULL; 
    struct addrinfo hints; 

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    iResult = getaddrinfo(host, port, &hints, &address);
    if (iResult != 0){
        return LIBRARY_FUNCTION_ERROR; 
    }

    connectSocket = socket(address->ai_family, address->ai_socktype, address->ai_protocol); 
    if (connectSocket == INVALID_SOCKET){
        freeaddrinfo(address); 
        return LIBRARY_FUNCTION_ERROR; 
    }

    iResult = connect(connectSocket, address->ai_addr, (int)address->ai_addrlen);
    freeaddrinfo(address);
    if (iResult == SOCKET_ERROR) {
        CLOSESOCKET(connectSocket); 
        connectSocket = INVALID_SOCKET;
        return LIBRARY_FUNCTION_ERROR;
    }

    #ifdef _WIN32 
    iResult = ioctlsocket(connectSocket, FIONBIO, &iMode); 
    #else
    iResult = fcntl(connectSocket, O_NONBLOCK, &iMode); 
    #endif

    //if (iResult != NO_ERROR) {
    //print
    //}

    MArgument_setInteger(Res, connectSocket); 
    return LIBRARY_NO_ERROR;
}

#pragma endregion

#pragma region socketBinaryWrite[socketId_Integer, data: ByteArray[<>], dataLength_Integer, bufferLength_Integer]: socketId_Integer 

DLLEXPORT int socketBinaryWrite(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    SOCKET clientId = MArgument_getInteger(Args[0]); 
    MNumericArray mArr = MArgument_getMNumericArray(Args[1]); 

    int iResult;
    BYTE *data = (BYTE *)libData->numericarrayLibraryFunctions->MNumericArray_getData(mArr); 
    int dataLength = MArgument_getInteger(Args[2]); 
    int bufferSize = MArgument_getInteger(Args[3]); 
    
    iResult = socketWrite(clientId, data, dataLength, bufferSize); 
    if (iResult == SOCKET_ERROR) {
        CLOSESOCKET(clientId);
        MArgument_setInteger(Res, -GETSOCKETERRNO()); 
        return LIBRARY_NO_ERROR; 
    }
    
    MArgument_setInteger(Res, clientId);
    return LIBRARY_NO_ERROR;
}

#pragma endregion

#pragma region socketWriteString[socketId_Integer, data_String, dataLength_Integer, bufferSize_Integer]: socketId_Integer 

DLLEXPORT int socketWriteString(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    int iResult; 
    SOCKET socketId = MArgument_getInteger(Args[0]); 
    char* data = MArgument_getUTF8String(Args[1]); 
    int dataLength = MArgument_getInteger(Args[2]); 
    int bufferSize = MArgument_getInteger(Args[3]); 
    
    iResult = socketWrite(socketId, data, dataLength, bufferSize); 
    if (iResult == SOCKET_ERROR) {
        CLOSESOCKET(socketId);
        MArgument_setInteger(Res, -GETSOCKETERRNO()); 
        return LIBRARY_NO_ERROR; 
    }
  
    MArgument_setInteger(Res, socketId);
    return LIBRARY_NO_ERROR;
}

#pragma endregion

#pragma region socketReadyQ[socketId_Integer]: readyQ: True | False 

DLLEXPORT int socketReadyQ(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    SOCKET socketId = MArgument_getInteger(Args[0]); 
    
    int iResult; 
    BYTE *buffer = (BYTE *)malloc(sizeof(BYTE)); 
    
    iResult = recv(socketId, buffer, 1, MSG_PEEK);
    if (iResult == SOCKET_ERROR){
        MArgument_setBoolean(Res, False); 
    } else {
        MArgument_setBoolean(Res, True); 
    }

    free(buffer);
    return LIBRARY_NO_ERROR;
}

#pragma endregion

#pragma region socketReadMessage[socketId_Integer, bufferSize_Integer]: ByteArray[<>] 

DLLEXPORT int socketReadMessage(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    SOCKET socketId = MArgument_getInteger(Args[0]);
    int bufferSize = MArgument_getInteger(Args[1]);
    
    BYTE *buffer = (BYTE*)malloc(bufferSize * sizeof(BYTE));
    int iResult;
    int length = 0;

    iResult = recv(socketId, buffer, bufferSize, 0);
    if (iResult > 0) {
        MArgument_setMNumericArray(Res, createByteArray(libData, buffer, iResult));
    } else {
        return LIBRARY_FUNCTION_ERROR;
    }

    return LIBRARY_NO_ERROR; 
}

#pragma endregion

#pragma region socketPort[socketId_Integer]: port_Integer

DLLEXPORT int socketPort(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
    SOCKET socketId = MArgument_getInteger(Args[0]); 
    struct  sockaddr_in sin;
    int port;
    int addrlen = sizeof(sin);

    getsockname(socketId, (struct sockaddr *)&sin, &addrlen);
    port = ntohs(sin.sin_port); 

    MArgument_setInteger(Res, port);
    return LIBRARY_NO_ERROR; 
}

#pragma endregion
