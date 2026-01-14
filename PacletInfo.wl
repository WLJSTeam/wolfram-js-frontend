(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "CoffeeLiqueur/WLJSNotebook",
    "Description" -> "Open-source Notebook Environment for Wolfram Language",
    "Creator" -> "WLJSTeam",
    "License" -> "GPL-3.0",
    "PublisherID" -> "CoffeeLiqueur",
    "Version" -> "3.0.0",
    "WolframVersion" -> "13+",
    "Extensions" -> {
      {
        "Kernel",
        "Root" -> "Kernel",
        "Context" -> {
          {"CoffeeLiqueur`Notebook`", "Notebook.wl"},
          {"CoffeeLiqueur`Notebook`Cells`", "Cells.wl"},
          {"CoffeeLiqueur`Notebook`Transactions`", "Transactions.wl"},
          {"CoffeeLiqueur`Notebook`Evaluator`", "Evaluator.wl"},
          {"CoffeeLiqueur`Notebook`Transactions`", "Transactions.wl"},

          {"CoffeeLiqueur`ExtensionManager`", "Extensions.wl"},

          {"CoffeeLiqueur`Notebook`Utils`", "Utils.wl"},
          {"CoffeeLiqueur`Notebook`FrontendObject`", "FrontendObject.wl"},
          {"CoffeeLiqueur`Notebook`Kernel`", "Kernel.wl"},
          {"CoffeeLiqueur`Notebook`LocalKernel`", "LocalKernel.wl"},
          {"KirillBelov`LTP`", "LTP.wl"},
          {"KirillBelov`LTP`Events`", "LTPEvents.wl"},
          {"CoffeeLiqueur`Notebook`FrontendObject`", "FrontendObject.wl"},
          {"CoffeeLiqueur`Notebook`MasterKernel`", "MasterKernel.wl"},

          {"CoffeeLiqueur`Notebook`AppExtensions`", "AppExtensions.wl"},


          {"CoffeeLiqueur`Notebook`Windows`", "Windows.wl"}
        }
      }
    }
  |>
]
