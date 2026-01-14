BeginPackage["KirillBelov`CSockets`Interface`Windows`Fallback`"]

Begin["`Private`"]

$libFile = FileNameJoin[{
	DirectoryName[$InputFileName],
	"wsockets.dll"
}]; 


If[FailureQ[
    socketOpen = LibraryFunctionLoad[$libFile, "socketOpen", {String, String}, Integer] 
],
    Echo["CSockets >> Windows >> Loading process failed. "];
    Exit[-1];
];


Echo["CSockets >> Windows >> Succesfully loaded!"];


(* ::Section:: *)
(*Implementation*)

createAsynchronousTask[socketId_, handler_, OptionsPattern[] ] := With[{},
    Internal`CreateAsynchronousTask[socketListen, {socketId, OptionValue["BufferSize"]}, handler]
];

Options[createAsynchronousTask] = {"BufferSize"->2^11}


socketClose = LibraryFunctionLoad[$libFile, "socketClose", {Integer}, Integer]; 
socketListen = LibraryFunctionLoad[$libFile, "socketListen", {Integer, Integer}, Integer]; 
socketListenerTaskRemove = LibraryFunctionLoad[$libFile, "socketListenerTaskRemove", {Integer}, Integer]; 
socketConnect = LibraryFunctionLoad[$libFile, "socketConnect", {String, String}, Integer]; 
socketBinaryWrite = LibraryFunctionLoad[$libFile, "socketBinaryWrite", {Integer, "ByteArray", Integer, Integer}, Integer]; 
socketWriteString = LibraryFunctionLoad[$libFile, "socketWriteString", {Integer, String, Integer, Integer}, Integer]; 
socketReadyQ = LibraryFunctionLoad[$libFile, "socketReadyQ", {Integer}, True | False]; 
socketReadMessage = LibraryFunctionLoad[$libFile, "socketReadMessage", {Integer, Integer}, "ByteArray"]; 
socketPort = LibraryFunctionLoad[$libFile, "socketPort", {Integer}, Integer]; 

End[]
EndPackage[]

{
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`createAsynchronousTask,
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketOpen,
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketClose,
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketBinaryWrite,
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketWriteString,

        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketConnect,

        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketReadyQ,
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketReadMessage,
        KirillBelov`CSockets`Interface`Windows`Fallback`Private`socketPort    
}

