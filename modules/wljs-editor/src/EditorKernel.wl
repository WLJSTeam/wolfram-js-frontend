BeginPackage["CoffeeLiqueur`Extensions`EditorView`", {"CoffeeLiqueur`Misc`Events`","CoffeeLiqueur`Misc`Events`Promise`", "CoffeeLiqueur`Misc`Parallel`", "CoffeeLiqueur`Extensions`FrontendObject`"}]

System`EditorView; (*make it available everywhere*)
System`CellView;


FrontEditorSelected::usage = "A frontend function FrontEditorSelected[\"Get\"] gets the selected content. FrontEditorSelected[\"Set\", value] inserts or replaces content"
EditorView::usage = "A view component for an editor instance EditorView[_String, opts___], where \"Event\" id can be provided for tracking changes. It supports dynamic updates as well."

CellView::usage = "A view component for an input or output cell CellView[_String, opts___], where \"Display\" is provided to choose a rendering view component"

InputEditor::usage = "InputEditor[string_] _EventObject"

MMAView::usage = "A view that returns a rasterized version of expr using Wolfram Mathematica frontened"

MMAViewAsync::usage = "Async version of MMAView"

FrontTextSelected::usage = "A frontend function FrontTextSelected[\"Get\"] gets the selected text (anywhere)"

Begin["`Private`"]

MMAView[ head_[all__], opts: OptionsPattern[] ] := (
  If[Length[Kernels[] ] == 0, LaunchKernels[1] ];
  WaitAll[ParallelSubmitFunctionAsync[Function[{args, cbk},
    cbk @ Rasterize[head @@ args, opts]
  ], {all}], 60 ]
)

MMAViewAsync[ head_[all__], opts: OptionsPattern[] ] := (
  If[Length[Kernels[] ] == 0, LaunchKernels[1] ];
  ParallelSubmitFunctionAsync[Function[{args, cbk},
    cbk @ Rasterize[head @@ args, opts]
  ], {all}]
)

SetAttributes[MMAView, HoldFirst]
SetAttributes[MMAViewAsync, HoldFirst]

Options[MMAView] = {ImageSize -> Automatic}
Options[MMAViewAsync] = {ImageSize -> Automatic}


InputEditor[str_String] := With[{id = CreateUUID[]},
    EventObject[<|"Id"->id, "Initial"->str, "View"->EditorView[str, "Event"->id]|>]
]

InputEditor[] := InputEditor[""]

InputEditor[str_] := With[{id = CreateUUID[]},
    EventObject[<|"Id"->id, "Initial"->First[str], "View"->EditorView[str, "Event"->id]|>]
]

System`WLXForm;

EditorView /: MakeBoxes[e_EditorView, WLXForm] := With[{o = CreateFrontEndObject[e]}, MakeBoxes[o, WLXForm] ]
CellView /: MakeBoxes[e_CellView, WLXForm] := With[{o = CreateFrontEndObject[e]}, MakeBoxes[o, WLXForm] ]

EditorView /: MakeBoxes[e_EditorView, StandardForm] := With[{o = CreateFrontEndObject[e]}, MakeBoxes[o, StandardForm] ]
CellView /: MakeBoxes[e_CellView, StandardForm] := With[{o = CreateFrontEndObject[e]}, MakeBoxes[o, StandardForm] ]

Options[CellView] = {"Display" -> "codemirror", "Class" -> "", "Style"->""}



End[]
EndPackage[]
