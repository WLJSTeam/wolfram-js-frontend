#!/usr/bin/env wolframscript
(* ::Package:: *)

<<KirillBelov`CSocketListener`
<<KirillBelov`TCPServer`


tcp = TCPServer[]


tcp["MessageHandler"] = Function[{client, data}, Echo[data]]


listener = CSocketListen[8080, tcp@Echo@#&]

Print[listener]


While[True, Pause[0.001]]
