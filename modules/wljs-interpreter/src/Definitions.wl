BeginPackage["CoffeeLiqueur`Extensions`WLJSInterpreter`"]

Alert::usage = "Alert[s_String] shows a modal alert window on browser's window"

System`AttachDOM;

AttachDOM::usage = "depricated"
WindowScope::usage = "WindowScope[name_String] gets Javascript object from the global scope"
Static::usage = "depricated"

ReadClipboard::usage = "ReadClipboard[] reads the text content from a clipboard"

System`ProvidedOptions;


EndPackage[]
