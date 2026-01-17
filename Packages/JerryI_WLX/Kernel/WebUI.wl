BeginPackage["JerryI`WLX`WebUI`", {"JerryI`WLX`Importer`", "JerryI`WLX`", "KirillBelov`WebSocketHandler`", "JerryI`Misc`Events`", "JerryI`Misc`Events`Promise`"}]

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
