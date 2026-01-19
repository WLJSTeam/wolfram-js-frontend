BeginPackage["CoffeeLiqueur`WLX`WebUI`", {"CoffeeLiqueur`WLX`Importer`", "CoffeeLiqueur`WLX`", "CoffeeLiqueur`WebSocketHandler`", "CoffeeLiqueur`Misc`Events`", "CoffeeLiqueur`Misc`Events`Promise`"}]

WebUILazyLoad;
WebUISubmit;
WebUILocation;
WebUIClose;
WebUIRefresh;
WebUIContainer;
WebUIJSBind;
WebUIOnLoad;
WebUIEventListener;
WebUIKeyListener;
WebUIFetch;
WebUIInitializationScript;

Begin["`Private`"]

{
    WebUILazyLoad, 
    WebUISubmit, 
    WebUILocation, 
    WebUIClose, 
    WebUIRefresh, 
    WebUIContainer, 
    WebUIJSBind, 
    WebUIOnLoad, 
    WebUIEventListener, 
    WebUIKeyListener, 
    WebUIFetch, 
    WebUIInitializationScript
} = ImportComponent[FileNameJoin[{$InputFileName // DirectoryName, "WebUI.wlx"}] ];

End[]
EndPackage[];
