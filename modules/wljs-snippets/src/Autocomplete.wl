BeginPackage["CoffeeLiqueur`Extensions`CommandPalette`AI`Autocomplete`", {
    "CoffeeLiqueur`Misc`Events`",
    "CoffeeLiqueur`Misc`Async`",
    "CoffeeLiqueur`Misc`Events`Promise`",
    "CoffeeLiqueur`Misc`WLJS`Transport`",
    "CoffeeLiqueur`Objects`",
    "CoffeeLiqueur`WLX`",
    "CoffeeLiqueur`WLX`Importer`"
}]

Begin["`Private`"]

Needs["CoffeeLiqueur`GPTLink`", FileNameJoin[{ParentDirectory[DirectoryName[$InputFileName] ], "packages", "GPTLink.wl"}] ];

Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];

Echo["Autocomplete AI loaded!"];

{loadSettings, storeSettings}        = ImportComponent["Frontend/Settings.wl"];

settings = <||>;
loadSettings[settings];


settingsKeyTable = {
    "Endpoint" -> "AIAssistantEndpoint",
    "Model" -> "AIAssistantModel",
    "MaxTokens" -> "AIAssistantMaxTokens",
    "Temperature" -> "AIAssistantTemperature",
    "Prompt" -> "AIAssistantAutocomplitPrompt"
};

getToken := SystemCredential["WLJSAI_API_KEY"]

getParameter[key_] := With[{
        params = Join[<|
            "AIAssistantEndpoint" -> "https://api.openai.com", 
            "AIAssistantModel" -> "gpt-4o", 
            "AIAssistantMaxTokens" -> 70000, 
            "AIAssistantTemperature" -> 0.3,
            "AIAssistantInitialPrompt" -> True,
            "AIAssistantLibraryStopList" -> {},
            "AIAssistantAutocomplit" -> False,
            "AIAssistantAutocomplitDelay" -> 400, 
            "AIAssistantAutocomplitPrompt"->"Work as autocomplete program. User sends prompts with code snippets, ^^ indicates the cursor positions (do not reply with ^^, this is inserted only for you). Reply only with this completion expression (DO NOT ESCAPE, NO ``` markdown structures) starting from the cursor position and replacing the whole line or return empty string if completion is not needed (no code escaping is needed). Apply syntax/spelling corrections if needed or possible. Most used languages: Wolfram, JS, MD, HTML, plain text"
        |>, settings],

        skey = key /. settingsKeyTable
    },

    params[skey]
]

inputDelay = getParameter["AIAssistantAutocomplitDelay"];

$rootDir =  ParentDirectory[ DirectoryName[$InputFileName] ];

        AppExtensions`TemplateInjection["AppTopBar"] = With[{
            script = Import[FileNameJoin[{$rootDir, "dist", "autocomplete.js"}], "Text"],
            delay = StringTemplate["window.SupportedCells['codemirror'].context.llmCompletionDelay = ``;"][inputDelay]
        }, 
            With[{
                final = "<script type=\"module\">"<>delay<>"\n\n"<>script<>"</script>"
            },
                Function[Null, final]
            ]
        ];

        bot = Null;

        gen[from_, to_, cellHash_] := With[{
            cell = cell`HashMap[ cellHash ],
            promise = Promise[], 
            sysP = getParameter["Prompt"]
        },

            If[bot === Null, 
      

                bot = GPTChatObject[
                    sysP,
                    "APIToken"->getToken, 
                    "Endpoint" -> getParameter["Endpoint"],
                    "Model" -> getParameter["Model"],
                    (* "Temperature" -> getParameter["Temperature"], *)
                    (* "Model" -> getParameter["Model"], *)
                    "MaxTokens" -> getParameter["MaxTokens"]
                ];

                Echo["Bot was created!"];
                Echo[ToString[bot, InputForm] ];
                Echo["System prompt for autocompletion:"];
                Echo[sysP];
            ];

            If[StringLength[StringTrim[cell["Data"] ] ] < 3,
                EventFire[promise, Resolve, False];
                Return[promise];
            ];

            With[{payload = truncateString[StringInsert[cell["Data"]<>" ", "^^", from], from, 1000]},
                If[Length[bot["Messages"] ] > 25, 
                    Echo["Dropping autocomplete messages"];
                    bot["Messages"] = Join[{bot["Messages"][[1]], bot["Messages"][[2]]}, Take[bot["Messages"], -10] ];
                ];

                GPTChatCompleteAsync[bot, payload, Function[Null, 
                    EventFire[promise, Resolve, bot["Messages"][[-1, "content"]] ];
                ] ];
            ];

            promise
        ];


        truncateString[str_String, center_Integer, max_Integer] := Module[
          {l = StringLength[str],
           contentLen, leftLen, rightLen, start, end, prefix, suffix, interior},

          (* If it's already short enough, just return it. *)
          If[l <= max,
            Return[str]
          ];

          (* How many chars we can show between the two “…” *)
          contentLen = max - 6;            (* 3 dots + content + 3 dots = max *)
          leftLen    = Floor[contentLen/2]; 
          rightLen   = contentLen - leftLen;

          (* Center that window on the requested index *)
          start = center - leftLen;
          end   = center + rightLen - 1;

          (* If we ran off the left edge, shift right *)
          If[start < 1,
            end   += 1 - start;
            start  = 1;
          ];
          (* If we ran off the right edge, shift left *)
          If[end > l,
            start -= end - l;
            end     = l;
          ];

          prefix = If[start > 1, "...", ""];
          suffix = If[end   < l, "...", ""];

          (* Build it *)
          prefix <> StringTake[str, {start, end}] <> suffix
        ];        

End[]
EndPackage[]