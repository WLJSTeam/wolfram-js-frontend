BeginPackage["CoffeeLiqueur`Patches`NoWR`"]

Begin["`Private`"]

With[{
  words = DeleteDuplicates @ 
    Select[StringLength[#] > 2 &] @ Flatten @ 
      Map[
        StringCases[#, 
          CharacterRange["A", "Z"] ~~ 
           Except[CharacterRange["A", "Z"]] ..] &] @ 
       Select[StringLength[#] > 2 &] @ 
        Names["System`*"]
  },
  Unprotect[RandomWord];
  ClearAll[RandomWord];
  
  RandomWord[] := RandomChoice @ words;
  RandomWord[n_Integer] := RandomChoice[words, n];
]

End[]

EndPackage[]