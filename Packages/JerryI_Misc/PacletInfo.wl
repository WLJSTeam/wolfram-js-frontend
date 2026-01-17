(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "JerryI/Misc",
    "Description" -> "Misc package with helpful tools",
    "Creator" -> "Kirill Vasin",
    "License" -> "MIT",
    "PublisherID" -> "JerryI",
    "Version" -> "0.5.7",
    "WolframVersion" -> "5+",
    "PrimaryContext" -> "JerryI`Misc`",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          {"JerryI`Misc`Events`", "Events.wl"}, 
          {"JerryI`Misc`Parallel`", "Parallel.wl"}, 
          {"JerryI`Misc`Events`Promise`", "Promise.wl"},
          {"JerryI`Misc`WLJS`Transport`", "WLJSIO.wl"}, 
          {"JerryI`Misc`Async`", "Async.wl"}, 
          {"JerryI`Misc`Language`", "Language.wl"}
        },
        "Symbols" -> {}
      },
 
      {
        "Asset",
        "Assets" -> {
          {"Assets", "InterpreterExtension.js"},
          {"Assets", "ServerAPI.js"}
        }
      }
    }
  |>
]
