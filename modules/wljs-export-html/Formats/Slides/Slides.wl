BeginPackage["CoffeeLiqueur`Extensions`ExportImport`Slides`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Async`",
    "JerryI`Misc`Events`Promise`",
    "JerryI`WLX`",
    "JerryI`WLX`Importer`",
    "JerryI`WLX`WebUI`", 
    "JerryI`Misc`WLJS`Transport`"
}];

Needs["CoffeeLiqueur`ExtensionManager`" -> "WLJSPackages`"];
Needs["CoffeeLiqueur`Notebook`AppExtensions`" -> "AppExtensions`"];

Needs["CoffeeLiqueur`Notebook`Cells`" -> "cell`"];
Needs["CoffeeLiqueur`Notebook`" -> "nb`"];


export;

Begin["`Private`"]



pdfEndpoint["Create", feobject_, OptionsPattern[] ] := With[{p = Promise[], channel = CreateUUID[], window = OptionValue["Window"], exposure = OptionValue["ExposureTime"], oversampling = OptionValue["ImageUpscaling"], landscape = OptionValue["Landscape"], crop = OptionValue["Crop"]},
  EventHandler[channel, Function[Null,
    EventFire[p, Resolve, <|"Window"->window, "crop"->crop|>];
  ] ];

  WebUISubmit[OverlayView["Create", feobject, channel, exposure, If[NumberQ[oversampling], oversampling, 1] ], window];

  p
]

pdfEndpoint["Capture", OptionsPattern[] ] := With[{p = Promise[], channel = CreateUUID[], window = OptionValue["Window"], exposure = OptionValue["ExposureTime"], oversampling = OptionValue["ImageUpscaling"], landscape = OptionValue["Landscape"], crop = OptionValue["Crop"]},
  Then[WebUIFetch[GetPDF["crop"->crop, "printBackground"->True, "preferCSSPageSize"->True, "scale"->1, "margins"-><|"right"->0, "left"->0, "top"->0, "bottom"->0|>], window, "Format"->"JSON"], Function[payload,
      EventFire[p, Resolve,  ByteArray[payload] ];
  ] ];
  p
]

pdfEndpoint["CaptureToMerger", OptionsPattern[] ] := With[{p = Promise[], channel = CreateUUID[], window = OptionValue["Window"], exposure = OptionValue["ExposureTime"], oversampling = OptionValue["ImageUpscaling"], landscape = OptionValue["Landscape"], crop = OptionValue["Crop"]},
  Then[WebUIFetch[AccumulatePDF @ GetPDF["crop"->crop, "printBackground"->True, "preferCSSPageSize"->True, "scale"->1, "margins"-><|"right"->0, "left"->0, "top"->0, "bottom"->0|>], window, "Format"->"JSON"], Function[payload,
      EventFire[p, Resolve,  True ];
  ] ];
  p
]

pdfEndpoint["FlushAndMerge", OptionsPattern[] ] := With[{p = Promise[], channel = CreateUUID[], window = OptionValue["Window"], exposure = OptionValue["ExposureTime"], oversampling = OptionValue["ImageUpscaling"], landscape = OptionValue["Landscape"], crop = OptionValue["Crop"]},
  Then[WebUIFetch[FlushPDF[], window, "Format"->"JSON"], Function[payload,
      EventFire[p, Resolve,  ByteArray[payload] ];
  ] ];
  p
]

pdfEndpoint["Destroy", OptionsPattern[] ] := With[{p = Promise[], channel = CreateUUID[], window = OptionValue["Window"], exposure = OptionValue["ExposureTime"], oversampling = OptionValue["ImageUpscaling"], landscape = OptionValue["Landscape"], crop = OptionValue["Crop"]},
  WebUISubmit[OverlayView["Dispose"], window];
]


Options[pdfEndpoint] = {"Crop"->True, "Window" :> Global`$Client, "ExposureTime" -> 2.0, "ImageUpscaling"->1, "Landscape"->True}



folder = $InputFileName // DirectoryName;
rootFolder = folder // ParentDirectory // ParentDirectory;

captureSlide[win_, delay_] := captureSlide[win, delay, Promise[] ]

captureSlide[win_, delay_, p_] := With[{},
    Then[pdfEndpoint["CaptureToMerger", "Window"->win ], Function[Null,
        Then[WebUIFetch[GetNextSlide[delay], win, "Format"->"JSON"], Function[result, 
            Echo["Result:"]; Echo[result];
            If[!TrueQ[result], 
                EventFire[p, Resolve, True];
            ,
                captureSlide[win, delay, p];
            ]
        ] ];
    ] ];
    p
] 

export[controls_, modals_, messager_, client_, notebookOnLine_nb`NotebookObj, path_, name_, ext_, settings_, _] := With[{

},
    With[{
        electronQ = WebUIFetch[CheckElectron[], client]
    },
      Then[electronQ, Function[isElectron,

        If[isElectron,
With[{
            p = Promise[],
            delay = Round[Lookup[settings, "ExportSlideExposureTime", 1.5] 1000]
        },
          
       EventFire[modals, "SaveDialog", <|
           "Promise"->p,
           "title"->"Export as PDF slides",
           "properties"->{"createDirectory", "dontAddToRecent"},
           "filters"->{<|"extensions"->"pdf", "name"->"PDF Document"|>}
       |>];


            AsyncFunction[win, With[{
                filename = Unique["htmlSlidesExporter"], payload = Unique["htmlSlidesExporter"],
                spinner = Unique["htmlSlidesExporter"], filenameRaw = Unique["htmlSlidesExporter"]
            }, 
                filenameRaw = p // Await;
                filename = If[StringQ[filenameRaw], URLDecode @ filenameRaw, URLDecode @ filenameRaw["filePath"] ];

                If[!StringQ[filename] || TrueQ[filenameRaw["canceled"] ] || StringLength[filename] === 0, 
                    Echo["Cancelled saving"]; Echo[filenameRaw];
                 
                ,

                    Echo[filename];
                    spinner = Notifications`Spinner["Topic"->"Exporting", "Body"->"Please, wait"];

                    If[!StringMatchQ[filename, __~~".pdf"],  filename = filename <> ".pdf"];
                    If[filename === ".pdf", filename = name<>filename];
                    If[DirectoryName[filename] === "", filename = FileNameJoin[{path, filename}] ];

                    With[{slides = Select[notebookOnLine["Cells"], Function[cell, cell["Display"] === "slide" && cell["Type"] === "Output" ] ]},
                        If[slides === {},
                            EventFire[messager, "Warning", "Notebook does not contain any output slide cells"];    
                            Delete[spinner];     
                            ClearAll[payload, filename, spinner];               
                        ,
                            EventFire[messager, spinner, True];

                            Delete /@ Drop[slides, 1];
                            EventFire[messager, "Info", "Please wait"];       

                            WebUIFetch[LoadPDFLibrary[], win] // Await;
                            pdfEndpoint["Create", HijackCellToContainer[slides[[1]]["Hash"], "border:1px solid #8585851a"], "Window"->win] // Await; 
                            PauseAsync[0.4] // Await;
                            WebUIFetch[ShakeSlide[], win] // Await;
                            PauseAsync[0.2] // Await;

                            captureSlide[win, delay] // Await;

                            slides[[1]] // Delete;
                            pdfEndpoint["Destroy", "Window"->win] // Await; 

                            payload = pdfEndpoint["FlushAndMerge", "Window"->win] // Await;   
                            Echo[payload // Head];
                            Echo[payload // Length];



                            With[{file = OpenWrite[filename, BinaryFormat->True]},
                                BinaryWrite[file, payload];
                                Close[file];
                                EventFire[messager, "Saved", "Exported to "<>filename];
                                Delete[spinner];     
                                ClearAll[payload, filename, spinner];
                            ];



                        ];

                    ];
                
                ];

            ] ][client];


                    

            
        ]        
        ,
            EventFire[messager, "Warning", "This feature requires WLJS Desktop App"];    
        ];

      ] ];    
        
    ]
]


End[]

EndPackage[]