(* ::Package:: *)

PacletObject[
  <|
    "Name" -> "JerryI/WolframJSFrontend",
    "Description" -> "Implementation of web-frontend for Wolfram Engine",
    "Creator" -> "Kirill Vasin",
    "License" -> "GPL-3.0",
    "PublisherID" -> "JerryI",
    "Version" -> "2.8.3",
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
