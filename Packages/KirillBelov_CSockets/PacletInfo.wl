(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "KirillBelov/CSockets",
    "Description" -> "Sockets powered by C and UV",
    "Creator" -> "Kirill Belov",
    "License" -> "MIT",
    "PublisherID" -> "KirillBelov",
    "Version" -> "1.2.0",
    "WolframVersion" -> "13+",
    "PrimaryContext" -> "KirillBelov`CSockets`",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          {"KirillBelov`CSockets`", "CSockets.wl"}, 
          {"KirillBelov`CSockets`EventsExtension`", "EventsExtension.wl"},
          {"KirillBelov`CSockets`Interface`Windows`", "Windows.wl"},
          {"KirillBelov`CSockets`Interface`Unix`", "Unix.wl"}
        },
        "Symbols" -> {
          "KirillBelov`CSockets`CSocketObject",
          "KirillBelov`CSockets`CSocketListener",
          "KirillBelov`CSockets`CSocketOpen",
          "KirillBelov`CSockets`CSocketConnect"
        }
      },
      {"LibraryLink", "Root" -> "LibraryResources"},
      {
        "Asset",
        "Assets" -> {
          {"License", "./LICENSE"},
          {"ReadMe", "./README.md"},
          {"Source", "./Source"},
          {"Scripts", "./Scripts"}
        }
      }
    }
  |>
]
