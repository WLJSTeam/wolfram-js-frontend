(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "CoffeeLiqueur/CSockets",
    "Description" -> "Sockets powered by C and UV",
    "Creator" -> "Kirill Belov",
    "License" -> "MIT",
    "PublisherID" -> "KirillBelov",
    "Version" -> "1.2.0",
    "WolframVersion" -> "13+",
    "PrimaryContext" -> "CoffeeLiqueur`CSockets`",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          {"CoffeeLiqueur`CSockets`", "CSockets.wl"}, 
          {"CoffeeLiqueur`CSockets`EventsExtension`", "EventsExtension.wl"},
          {"CoffeeLiqueur`CSockets`Interface`Windows`", "Windows.wl"},
          {"CoffeeLiqueur`CSockets`Interface`Unix`", "Unix.wl"}
        },
        "Symbols" -> {
          "CoffeeLiqueur`CSockets`CSocketObject",
          "CoffeeLiqueur`CSockets`CSocketListener",
          "CoffeeLiqueur`CSockets`CSocketOpen",
          "CoffeeLiqueur`CSockets`CSocketConnect"
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
