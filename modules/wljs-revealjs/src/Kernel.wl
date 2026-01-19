BeginPackage["CoffeeLiqueur`Extensions`SlidesTools`", {"CoffeeLiqueur`Misc`Events`", "CoffeeLiqueur`Extensions`Communication`"}]

SlideEventListener::usage = "SlideEventListener[\"Id\"->\"event-uid\"] attach an event generator from slide to event-uid"
FrontSlidesSelected::usage = "A frontend function, that gives access to current slide FrontSlidesSelected[command_, data_]"


Begin["`Private`"]


SlideEventListener[OptionsPattern[]] := StringTemplate["RVJSEvent[\"``\",\"``\"]"][OptionValue["Id"], OptionValue["Pattern"] ]
Options[SlideEventListener] = {"Id"->"default-slide-event", "Pattern"->"Slide"}

End[]
EndPackage[]
