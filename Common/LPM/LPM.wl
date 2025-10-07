BeginPackage["JerryI`LPM`"]

PacletRepositories::usage = "depricated"
LPMRepositories::usage = "LPMRepositories[{\"Github\" -> \"URL to the repo\", ...}] specify the wolfram packages to be synced via remote url"
LPMLoad::usage = "LPMLoad[\"Directory\"->...] loads paclets stored by LPMRepositories[] without checking updates and etc"
Github::usage = "depricated"


Begin["`Private`"]

pacletDirectoryLoad = PacletDirectoryLoad

urlImport = Import;
urlDownload= URLDownload;
urlGet = Get;

convertVersion[str_String] := ToExpression[StringReplace[str, "."->""]]
convertVersion[any_PacletObject] := convertVersion[any["Version"]]


inspectPackages[dir_String, cbk_] := Module[{ 
  packages
},
  packages = Get /@ DeleteDuplicatesBy[FileNames["PacletInfo.wl" | "PacletInfo.m", {dir}, {2}], DirectoryName];

  With[{found = SortBy[PacletFind[#["Name"] ], convertVersion]},

    If[Length[found] > 0,
      With[{conflicting = found // Last},
        If[convertVersion[conflicting] > convertVersion[#],
          Echo[StringTemplate["LPM >> Conflicting version of ``!!! Globally installed `` vs locally loaded ``"][#["Name"], convertVersion[conflicting], convertVersion[#] ] ];
          cbk[conflicting, #];
        ]
      ]
    ]
  ] &/@ packages;
]

LPMRepositories = PacletRepositories;

LPMLoad[OptionsPattern[] ] := Module[{projectDir},
  If[OptionValue["Directory"]//StringQ,
    projectDir = OptionValue["Directory"];
    If[!StringQ[projectDir], Echo["LPM >> Sorry. This is a wrong folder!"]; Abort[]];
  ,
    projectDir = NotebookDirectory[] // Quiet;
    If[!StringQ[projectDir], projectDir = DirectoryName[$InputFileName]];
    If[!StringQ[projectDir], Echo["LPM >> Sorry. We cannot work without a project directory. Save your notebook / script first"]; Abort[]];    
  ];

  If[FileExistsQ[FileNameJoin[{projectDir, "wl_packages"}] ], Map[pacletDirectoryLoad] @  Map[DirectoryName] @  DeleteDuplicatesBy[FileNames["PacletInfo.wl" | "PacletInfo.m", {#}, {2}], DirectoryName]& @ FileNameJoin[{projectDir, "wl_packages"}], $Failed]
]

Options[LPMLoad] = {"Directory"->None}

PacletRepositories[list_List, OptionsPattern[]] := Module[{projectDir, strictMode = OptionValue["StrictMode"], info, repos, cache, updated, removed, new, current, updatable, skipUpdates = OptionValue["Passive"], automaticUpdates = OptionValue["AutomaticUpdates"], versionControl, maxVersionDiff = OptionValue["MaxVersionDiff"]},
    (* making key-values pairs *)
    repos = (#-><|"key"->#|>)&/@list // Association;

    (* locating project directory *)
    If[OptionValue["Directory"]//StringQ,
      projectDir = OptionValue["Directory"];
      If[!StringQ[projectDir], Echo["LPM >> Sorry. This is a wrong folder!"]; Abort[]];
    ,
      projectDir = NotebookDirectory[] // Quiet;
      If[!StringQ[projectDir], projectDir = DirectoryName[$InputFileName]];
      If[!StringQ[projectDir], Echo["LPM >> Sorry. We cannot work without a project directory. Save your notebook / script first"]; Abort[]];    
    ];

    If[!FileExistsQ[projectDir],
      CreateDirectory[projectDir, CreateIntermediateDirectories->True];
      If[!FileExistsQ[projectDir], Echo["LPM >> Cannot create project directory by path "<>projectDir<>" !!!"]; Abort[] ];
    ];

    (* PASSIVE mode :: skips all checks and just loads wl_package folder *)
    If[skipUpdates, 
      inspectPackages[FileNameJoin[{projectDir, "wl_packages"}], OptionValue["ConflictResolutionFunction"] ];
      Map[pacletDirectoryLoad] @  Map[DirectoryName] @  DeleteDuplicatesBy[FileNames["PacletInfo.wl" | "PacletInfo.m", {#}, {2}], DirectoryName]& @ FileNameJoin[{projectDir, "wl_packages"}];
      Return[Null, Module];
    ];

    Echo["LPM >> fetching packages info"];

    If[FailureQ[ URLFetch["https://github.com"] ],
        Echo["LPM >> ERROR! no connection to github.com!"];

        If[!MissingQ[cache], 
          Echo["LPM >> using stored data"];
          inspectPackages[FileNameJoin[{projectDir, "wl_packages"}], OptionValue["ConflictResolutionFunction"] ];
          Map[pacletDirectoryLoad] @  Map[DirectoryName] @  DeleteDuplicatesBy[FileNames["PacletInfo.wl" | "PacletInfo.m", {#}, {2}], DirectoryName]& @ FileNameJoin[{projectDir, "wl_packages"}];
          Return[Null, Module];
        ,
          Echo["LPM >> ERROR! no cache found ;()"];
          Abort[];
        ];
    ];

    (* fetching new information from Github for each repo in the list *)
    repos = If[!AssociationQ[#], Missing[], #] &/@ FetchInfo /@ repos;

    repos = repos // DeleteMissing;

    (* fetching cached data (current status of all packages in the project) *)
    Echo["LPM >> checking cached"];
    cache = CacheLoad[projectDir];



    (* if there is no cache -> *)
    If[MissingQ[cache], 
      (* nothing is installed! Install them all *)
      repos = InstallPaclet[projectDir] /@ repos;
    ,
      (* we have local versions of all packages *)
      (* we need to compare them to one, which were just loaded via internet *)

      removed =  (#->cache[#])&/@ Complement[Keys[cache], Keys[repos]] // Association;
      current    =  (#->cache[#])&/@ Intersection[Keys[repos], Keys[cache]] // Association;
      new = (#->repos[#])&/@ Complement[Keys[repos], Keys[cache]] // Association;

      Echo[StringTemplate["LPM >> will be REMOVED: ``"][Length[removed]]];
      Echo[StringTemplate["LPM >> will be INSTALLED: ``"][Length[new]]];
     
      (* remove unecessary (a user removed them) *)
      RemovePaclet[projectDir] /@ removed;
      (* install new *)
      new = InstallPaclet[projectDir] /@ new;

      (* what must be updated *)
      If[automaticUpdates,
        updatable = Select[current, CheckUpdates];
      ,
        Echo["LPM >> Automatic updates are suppressed by default"];
        updatable = <||>;
      ];

      (* will be updated *)
      updated   = ((#->repos[#])&/@ Keys[updatable]) // Association;
 
      Echo[StringTemplate["LPM >> will be UPDATED: ``"][Length[updatable]]];

      (* update our list with fresh data *)
      repos = Join[current, InstallPaclet[projectDir] /@ updated, new];
    ];

    (* update local cache file aka packages.json *)
    CacheStore[projectDir, repos];

    (* finally load dirs *)
    inspectPackages[FileNameJoin[{projectDir, "wl_packages"}], OptionValue["ConflictResolutionFunction"] ];
    Map[pacletDirectoryLoad] @  Map[DirectoryName] @  DeleteDuplicatesBy[FileNames["PacletInfo.wl" | "PacletInfo.m", {#}, {2}], DirectoryName]& @ FileNameJoin[{projectDir, "wl_packages"}];
]

Options[PacletRepositories] = {"Directory"->None, "StrictMode"->False, "Passive"->False, "ForceUpdates" -> False, "AutomaticUpdates"->True, "MaxVersionDiff" -> None, "UpdateInterval" -> Quantity[14, "Days"], "ConflictResolutionFunction" -> Function[{conflicting, true}, 
  Echo["LPM >> resolving by uninstalling a global one"];
  If[PacletUninstall[conflicting] =!= Null,
    Echo["FAILED!"];
    Exit[-1];
  ];
]}

CacheStore[dir_String, repos_Association] := Export[FileNameJoin[{dir, "wl_packages_lock.wl"}], repos]
CacheLoad[dir_String] := If[!FileExistsQ[FileNameJoin[{dir, "wl_packages_lock.wl"}]], Missing[], Import[FileNameJoin[{dir, "wl_packages_lock.wl"}]]];

CheckUpdates[a_Association] := Module[{result},
  CheckUpdates[a, a["key"]]
]

convertVersion[str_String] := ToExpression[StringReplace[str, "." -> ""]]

(* general function work for both Releases & Branches *)
CheckUpdates[a_Association, Rule[Github | "Github", _]] := Module[{package, new, now},
  (* fetch any *)
  package = FetchInfo[a];
  If[!AssociationQ[package], Echo["LPM >> cannot check. Skipping..."]; Return[False, Module]];

  (* a feature on how we can detect on what we are looking at *)
  If[KeyExistsQ[package, "tag_name"],
    (* releases *)
    new = package["tag_name"] // convertVersion;
    now = a["tag_name"] //convertVersion;

    (* if there was no available releases before and now it appeared, there will be missmatch *)
    If[!NumericQ[now], now = -1];

    Echo[StringTemplate["LPM >> installed `` remote ``"][now, new]];
    now < new  
  ,
    (* branches *)
    new = package["Version"] // convertVersion;
    now = a["Version"] //convertVersion;
    If[!NumericQ[now], now = -1];

    Echo[StringTemplate["LPM >> installed `` remote ``"][now, new]];
    now < new  
  ]
]

(* general function to fetch information about the package *)
FetchInfo[a_Association] := Module[{result},
  FetchInfo[a, a["key"]]
]

(* for releases *)
FetchInfo[a_Association, Rule[Github | "Github", url_String]] := Module[{new, data},
  (* extracting from given url *)
  new = StringCases[url, RegularExpression[".com\\/(.*).git"]->"$1"]//First // Quiet;
    If[!StringQ[new], new = StringCases[url, RegularExpression[".com\\/(.*)"]->"$1"]//First];
    Echo["LPM >> fetching releases info for "<>new<>" on Github..."];

  (* here we FETCH GITHUB API RESPONCE and use releases metadata *)
  data = urlImport["https://api.github.com/repos/"<>new<>"releases/latest", "JSON"] // Association // Quiet;

  (* if there is NO RELEASES *)
  If[!StringQ[data["zipball_url"]],
    Print["Releases are not available. Taking a master branch"];
    (* TAKE MASTER Branch *)
    Return[FetchInfo[a, Rule["Github", Rule[url, "master"]]]];
  ];

  (* merge new and old data together *)
  Join[a, data, <|"git-url"->new|>]
]

(* for branches *)
FetchInfo[a_Association, Rule[Github | "Github", Rule[url_String, branch_String]]] :=
Module[{new, data},
  (* extracting from given url *)    
    new = StringCases[url, RegularExpression[".com\\/(.*).git"]->"$1"]//First // Quiet;
    If[!StringQ[new], new = StringCases[url, RegularExpression[".com\\/(.*)"]->"$1"]//First];
    Echo["LPM >> fetching info for "<>new<>" on Github..."];

    (* here we FETCH PACLETINFO.WL file and use its metadata *)
    data = urlGet["https://raw.githubusercontent.com/"<>new<>"/"<>ToLowerCase[branch]<>"/PacletInfo.wl"] // Quiet;
    If[!MatchQ[ToString[Head[data] ], "PacletObject" | "Paclet"], 
      data = urlGet["https://raw.githubusercontent.com/"<>new<>"/"<>ToLowerCase[branch]<>"/PacletInfo.m"];
    ];

    (* if failed. we just STOP *)

    If[!MatchQ[ToString[Head[data] ], "PacletObject" | "Paclet"], (* some issue with contexts *)
      Echo["Failed"];
      Echo[ToString[data, InputForm] ];
      Echo["LPM >> ERROR cannot get "<>new<>"!"];
      Echo["LPM >> Aborting"];
      Abort[];
    ];

    Join[a, Switch[ToString[Head[data] ], "PacletObject", data//First, "Paclet", Association @ KeyValueMap[Function[{k,v}, ToString[k]->v], Association @@ data] ], <|"git-url"->new|>]
]

(* general function *)
InstallPaclet[dir_String][a_Association] := InstallPaclet[dir][a, a["key"]]

(* releases *)
InstallPaclet[dir_String][a_Association, Rule[Github | "Github", url_String]] := Module[{dirName, pacletPath},
    dirName = FileNameJoin[{dir, "wl_packages"}];
    If[!FileExistsQ[dirName], CreateDirectory[dirName]];

    (* check if there is no data on releases -> *)
    If[MissingQ[a["zipball_url"]], 
      (* TAKE Master branch instead *)
      Echo["LPM >> Releases are not available. Taking a master branch"];
      Return[InstallPaclet[dir][a, Rule["Github", Rule[url, "master"]]]];
    ];

    (* make a name from the git url provided *)
    dirName = FileNameJoin[{dirName, StringReplace[a["git-url"], "/"->"_"]}];

    (* in a case of update, directory will probably be there.. cleaning it! *)
    If[FileExistsQ[dirName],
        Echo["LPM >> package folder already exists!"];
        Echo["LPM >> purging..."];
        DeleteDirectory[dirName, DeleteContents -> True];
    ];

    (* download release *)
    Echo["LPM >> fetching a release"];    
    urlDownload[a["zipball_url"], FileNameJoin[{dir, "___temp.zip"}]];
    
    (* extract to temporary directory and copy *)
    Echo["LPM >> extracting"];
    ExtractArchive[FileNameJoin[{dir, "___temp.zip"}], FileNameJoin[{dir, "___temp"}]];
    DeleteFile[FileNameJoin[{dir, "___temp.zip"}]];
    
    (* locate PacletInfo, if it is not there, this is very bad. *)
    pacletPath = FileNames["PacletInfo.wl" | "PacletInfo.m", FileNameJoin[{dir, "___temp"}], 2] // First;

    If[!FileExistsQ[pacletPath], Echo["LPM >> FAILED!!! to fetch by "<>ToString[pacletPath]]; Abort[]];
    pacletPath = DirectoryName[pacletPath];

    Echo[StringTemplate["LPM >> copying from `` to ``"][pacletPath, dirName]];
 
    CopyDirectory[pacletPath, dirName];
    DeleteDirectory[FileNameJoin[{dir, "___temp"}], DeleteContents -> True];
    Print["LPM >> finished"];

    a
]

(* for branch *)
InstallPaclet[dir_String][a_Association, Rule[Github | "Github", Rule[url_String, branch_String]]] := Module[{dirName, pacletPath},
    dirName = FileNameJoin[{dir, "wl_packages"}];
    If[!FileExistsQ[dirName], CreateDirectory[dirName]];

    (* internal error, if there is no url provided *)
    If[MissingQ[a["git-url"]], Echo["LPM >> ERROR!!! not git-url was found"]; Abort[]];

    (* construct name of the folder *)
    dirName = FileNameJoin[{dirName, StringReplace[Lookup[a, "Name", a[Name] ], "/"->"_"]}];

    If[FileExistsQ[dirName],
        Echo["LPM >> package folder "<>dirName<>" already exists!"];
        Echo["LPM >> purging..."];
        DeleteDirectory[dirName, DeleteContents -> True];
    ];

    (* download branch as zip using old API *)
    Echo["LPM >> fetching a zip archive from the master branch..."];    
    urlDownload["https://github.com/"<>a["git-url"]<>"/zipball/"<>ToLowerCase[branch], FileNameJoin[{dir, "___temp.zip"}]];
    
    Echo["LPM >> extracting"];
    ExtractArchive[FileNameJoin[{dir, "___temp.zip"}], FileNameJoin[{dir, "___temp"}]];
    DeleteFile[FileNameJoin[{dir, "___temp.zip"}]];
    
    pacletPath = FileNames["PacletInfo.wl" | "PacletInfo.m", FileNameJoin[{dir, "___temp"}], 2] // First;

    If[!FileExistsQ[pacletPath], Echo["LPM >> FAILED!!! to fetch by "<>ToString[pacletPath]]; Abort[]];
    pacletPath = DirectoryName[pacletPath];

    Echo[StringTemplate["LPM >> copying from `` to ``"][pacletPath, dirName]];
 
    CopyDirectory[pacletPath, dirName];
    DeleteDirectory[FileNameJoin[{dir, "___temp"}], DeleteContents -> True];
    Print["LPM >> finished"];

    a
]


(* general function *)
RemovePaclet[dir_String][a_Association] := RemovePaclet[dir][a, a["key"]]

(* releases *)
RemovePaclet[dir_String][a_Association, Rule[Github | "Github", url_String]] := (
  
  If[MissingQ[a["zipball_url"]], 
    Echo["LPM >> Releases are not available. Removing master"];
    Return[RemovePaclet[dir][a, Rule["Github", Rule[url, "master"]]]];
  ];  

  dirName = FileNameJoin[{dir, "wl_packages"}];
  dirName = FileNameJoin[{dirName, StringReplace[a["git-url"], "/"->"_"]}];

  If[FileExistsQ[dirName],
      Echo["LPM >> package folder "<>dirName<>" is about to be removed"];
      Echo["LPM >> purging..."];
      DeleteDirectory[dirName, DeleteContents -> True];
  ,
      Echo["LPM >> package folder "<>dirName<>" was already removed!"];
      Echo["LPM >> UNEXPECTED BEHAVIOUR!"]; Abort[];
  ];

  a  
)

(* branches *)
RemovePaclet[dir_String][a_Association, Rule[Github | "Github", Rule[url_String, branch_String]]] := Module[{dirName, pacletPath},
    dirName = FileNameJoin[{dir, "wl_packages"}];
    dirName = FileNameJoin[{dirName, StringReplace[a["Name"], "/"->"_"]}];

    If[FileExistsQ[dirName],
        Echo["LPM >> package folder "<>dirName<>" is about to be removed"];
        Echo["LPM >> purging..."];
        DeleteDirectory[dirName, DeleteContents -> True];
    ,
        Echo["LPM >> package folder "<>dirName<>" was already removed!"];
        Echo["LPM >> UNEXPECTED BEHAVIOUR!"]; Abort[];
    ];

    a
]

End[]

EndPackage[]
