(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "JerryI/WLX",
    "Description" -> "Wolfram Language XML syntax extension (a superset of WL and XML)",
    "Creator" -> "Kirill Vasin",
    "License" -> "GPL-3.0-only",
    "PublisherID" -> "JerryI",
    "Version" -> "2.0.9",
    "WolframVersion" -> "13+",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          {"JerryI`WLX`", "WLX.wl"},
          {"JerryI`WLX`Importer`", "Importer.wl"},
          {"JerryI`WLX`WLJS`", "WLJS.wl"},
          {"JerryI`WLX`WebUI`", "WebUI.wl"}
        },
        "Symbols" -> {}
      },
      {
        "Asset",
        "Assets" -> {
          {"ReadMe", "./README.md"},
          {"Kit", {"Kernel", "WebUI.wlx"}},
          {"ExamplesFolder", "./Examples"},
          {"Image", "./logo.png"}
        }
      }
    },
    "PrimaryContext" -> "JerryI`WLX`"
  |>
]
