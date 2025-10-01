BeginPackage["CoffeeLiqueur`Notebook`AppExtensions`"]

AppExtensions;
ExtensionEvent;

AppEvents;
AppProtocol;
FrontendEnv;

SidebarIcons;

HTTPFileExtensions;

WebServers;

HTTPHandler;
KernelList;

QuickNotesDir;
BackupsDir;
DefaultDocumentsDir;
DemosDir;
ExtensionsDir;
AppDataDir;
AppConfig;

Templates;
TemplateInjection;

Begin["`Internal`"];

templates = <||>;

emptyStringFunction[x__] := ""

WebServers = <||>;

Templates[ opts: OptionsPattern[] ] := With[{template = OptionValue["Template"]},
    If[KeyExistsQ[templates, template],
        #[opts] &/@ templates[template]
    ,
        emptyStringFunction[opts]
    ]
]

HTTPHandler = Null

sidebarIcons = {};
SidebarIcons := sidebarIcons
SidebarIcons /: Set[SidebarIcons, list_List] := (sidebarIcons = Join[sidebarIcons, list])

Options[Templates] = {"Template" -> ""}

(* global event object *)
AppEvents      = "AppEvents"; 
AppProtocol = "AppProtocol$::";

TemplateInjection /: Set[TemplateInjection[template_String], function_] := With[{},
    If[KeyExistsQ[templates, template],
        templates[template] = Append[templates[template], function];
    ,
        templates[template] = {function}
    ];
]


End[]
EndPackage[]