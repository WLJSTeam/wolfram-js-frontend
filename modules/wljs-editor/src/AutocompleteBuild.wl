Needs["CodeParser`"]
Needs["CodeParser`Utils`"]

(* https://github.com/WolframResearch/LSPServer/blob/master/LSPServer *)

replaceLongNamePUA[s_] := s;

linearToMDSyntax[str_] := 
Module[{},
  reassembleEmbeddedLinearSyntax[CodeTokenize[str]] /. {
    LeafNode[Token`Newline, _, _] -> "\n\n",
    LeafNode[Token`LinearSyntax`Bang, _, _] -> "",
    LeafNode[Token`LinearSyntaxBlob, s_, _] :> parseLinearSyntaxBlob[s],
    LeafNode[String, s_, _] :> parseString[s],
    LeafNode[_, s_, _] :> escapeMarkdown[replaceLinearSyntax[replaceControl[s]]],
    ErrorNode[_, s_, _] :> escapeMarkdown[replaceLinearSyntax[replaceControl[s]]]
  }
]





parseLinearSyntaxBlob[s_] :=
Module[{res},
  res = Quiet[ToExpression[s]];
  If[FailureQ[res],
    Message[interpretBox::failed];
  ];
  interpretBox[res]
]

parseString[s_] :=
Module[{a1, unquoted, hasStartingQuote, hasEndingQuote},

  (*
  The string may be reassembled and there may have been an error in the linear syntax,
  meaning that there is no trailing quote
  *)
  hasStartingQuote = StringMatchQ[s, "\"" ~~ ___];
  hasEndingQuote = StringMatchQ[s, ___ ~~ "\""];
  unquoted = StringReplace[s, (StartOfString ~~ "\"") | ("\"" ~~ EndOfString) -> ""];

  a1 = reassembleEmbeddedLinearSyntax[CodeTokenize[unquoted]] /. {
    LeafNode[Token`LinearSyntax`Bang, _, _] -> "",
    LeafNode[Token`LinearSyntaxBlob, s1_, _] :> parseLinearSyntaxBlob[s1],
    LeafNode[String, s1_, _] :> parseString[s1],
    LeafNode[_, s1_, _] :> escapeMarkdown[replaceLinearSyntax[replaceControl[replaceLongNamePUA[s1]]]],
    ErrorNode[_, s1_, _] :> escapeMarkdown[replaceLinearSyntax[replaceControl[replaceLongNamePUA[s1]]]]
  };
  {If[hasStartingQuote, "\"", ""], a1, If[hasEndingQuote, "\"", ""]}
]


(* :!CodeAnalysis::BeginBlock:: *)
(* :!CodeAnalysis::Disable::UnexpectedCharacter:: *)

interpretBox::unhandled = "unhandled: `1`"

interpretBox::unhandledgridbox = "unhandled GridBox"

interpretBox::unhandledSeq = "unhandled: letter sequence that should probably be a RowBox: \n`1`\nIf this looks like boxes, then this is a strange usage message."

interpretBox::unhandled2 = "unhandled: `1`. If this looks like a correct box, then please add to interpretBox. Otherwise, this is a strange usage message."

interpretBox::failed = "unhandled: Linear syntax could not be parsed by ToExpression."

interpretBox[RowBox[children_]] :=
  interpretBox /@ children

(*
HACK: BeginPackage::usage has typos

TR symbol instead of "TR"
*)
(* interpretBox[StyleBox[a_, TR]] :=
  interpretBox[a] *)

interpretBox[StyleBox[a_, "TI", ___Rule]] :=
  {"<i>", interpretBox[a], "</i>"}

interpretBox[StyleBox[a_, Bold, ___Rule]] :=
  {"<b>", interpretBox[a], "</b>"}

interpretBox[StyleBox[a_, _String, ___Rule]] :=
  interpretBox[a]

interpretBox[StyleBox[a_, ___Rule]] :=
  interpretBox[a]

interpretBox[StyleBox[___]] := (
  Message[interpretBox::unhandled, "StyleBox with weird args"];
  "\[UnknownGlyph]"
)

interpretBox[SubscriptBox[a_, b_]] :=
  interpretBox /@ {a, "<sub>", b, "</sub>"}

interpretBox[SuperscriptBox[a_, b_, ___Rule]] :=
  interpretBox /@ {a, "<sup>", b, "</sup>"}

interpretBox[SubsuperscriptBox[a_, b_, c_]] :=
  interpretBox /@ {a, "<sub>", b, "</sub><sup>", c, "</sup>"}

interpretBox[FractionBox[a_, b_]] :=
  interpretBox /@ {a, "/", b}

interpretBox[TagBox[a_, _, ___Rule]] :=
  interpretBox[a]

interpretBox[FormBox[a_, _]] :=
  interpretBox[a]

interpretBox[TooltipBox[a_, _]] :=
  interpretBox[a]

interpretBox[UnderscriptBox[a_, b_, ___Rule]] :=
  interpretBox /@ {a, "+", b}

interpretBox[OverscriptBox[a_, b_]] :=
  interpretBox /@ {a, "&", b}

interpretBox[UnderoverscriptBox[a_, b_, c_, ___Rule]] :=
  interpretBox /@ {a, "+", b, "%", c}

interpretBox[GridBox[_, ___Rule]] := (
  Message[interpretBox::unhandledgridbox];
  "\[UnknownGlyph]"
)

interpretBox[CheckboxBox[_]] := (
  Message[interpretBox::unhandled, "CheckboxBox"];
  "\[UnknownGlyph]"
)

interpretBox[CheckboxBox[_, _]] := (
  Message[interpretBox::unhandled, "CheckboxBox"];
  "\[UnknownGlyph]"
)

interpretBox[DynamicBox[_, ___]] := (
  Message[interpretBox::unhandled, "DynamicBox"];
  "\[UnknownGlyph]"
)

interpretBox[TemplateBox[_, _]] := (
  Message[interpretBox::unhandled, "TemplateBox"];
  "\[UnknownGlyph]"
)

interpretBox[SqrtBox[a_]] :=
  interpretBox /@ {"@", a}

interpretBox[OpenerBox[_]] := (
  Message[interpretBox::unhandled, "OpenerBox"];
  "\[UnknownGlyph]"
)

interpretBox[RadioButtonBox[_, _]] := (
  Message[interpretBox::unhandled, "RadioButtonBox"];
  "\[UnknownGlyph]"
)

interpretBox[RadicalBox[a_, b_]] :=
  interpretBox /@ {"@", a, "%", b}

interpretBox[s_String /; StringMatchQ[s, WhitespaceCharacter... ~~ "\"" ~~ __ ~~ "\"" ~~ WhitespaceCharacter...]] :=
  parseString[s]

(*
Sanity check that the box that starts with a letter is actually a single word or sequence of words
*)
interpretBox[s_String /; StringStartsQ[s, LetterCharacter | "$"] &&
  !StringMatchQ[s, (WordCharacter | "$" | " " | "`" | "_" | "/" | "\[FilledRightTriangle]") ...]] := (
  Message[interpretBox::unhandledSeq, s];
  "\[UnknownGlyph]"
)

interpretBox[s_String] :=
  escapeMarkdown[replaceLinearSyntax[replaceControl[replaceLongNamePUA[s]]]]

interpretBox[$Failed] := (
  "\[UnknownGlyph]"
)

interpretBox[s_Symbol] := (
  (*
  This is way too common to ever fix properly, so concede and convert to string
  *)
  (* Message[interpretBox::unhandled, Symbol];
  "\[UnknownGlyph]" *)
  ToString[s]
)

(*
HACK: BeginPackage::usage has typos
*)
(* interpretBox[i_Integer] := (
  Message[interpretBox::unhandled, Integer];
  "\[UnknownGlyph]"
) *)

(*
HACK: Riffle::usage has a Cell expression
*)
interpretBox[Cell[BoxData[a_], _String, ___Rule]] := (
  Message[interpretBox::unhandled, Cell];
  "\[UnknownGlyph]"
)

interpretBox[Cell[TextData[a_], _String, ___Rule]] := (
  Message[interpretBox::unhandled, Cell];
  "\[UnknownGlyph]"
)

(*
HACK: RandomImage::usage has a typos (missing comma) and creates this expression:
("")^2 (", ")^2 type
*)
(* interpretBox[_Times] := (
  Message[interpretBox::unhandled, "strange Times (probably missing a comma)"];
  "\[UnknownGlyph]"
) *)

(*
HACK: NeuralFunctions`Private`MaskAudio::usage has weird typos
*)
(* interpretBox[_PatternTest] := (
  Message[interpretBox::unhandled, "strange PatternTest"];
  "\[UnknownGlyph]"
) *)

interpretBox[b_] := (
  Message[interpretBox::unhandled2, b];
  "\[UnknownGlyph]"
)


escapeMarkdown[s_String] :=
  StringReplace[s, {
    (*
    There is some bug in VSCode where it seems that the mere presence of backticks prevents other characters from being considered as escaped

    For example, look at BeginPackage usage message in VSCode
    *)

    "&" -> "&amp;"
  }]




(*
FIXME: maybe have some nicer replacement strings
do not necessarily have to display the escape sequence
*)
replaceControl[s_String] :=
  StringReplace[s, {
    (*
    ASCII control characters
    *)
    "\.00" -> "\\.00",
    "\.01" -> "\\.01",
    "\.02" -> "\\.02",
    "\.03" -> "\\.03",
    "\.04" -> "\\.04",
    "\.05" -> "\\.05",
    "\.06" -> "\\.06",
    "\.07" -> "\\.07",
    "\b" -> "\\b",
    (*\t*)
    (*\n*)
    "\.0b" -> "\\.0b",
    "\f" -> "\\f",
    (*\r*)
    "\.0e" -> "\\.0e",
    "\.0f" -> "\\.0f",
    "\.10" -> "\\.10",
    "\.11" -> "\\.11",
    "\.12" -> "\\.12",
    "\.13" -> "\\.13",
    "\.14" -> "\\.14",
    "\.15" -> "\\.15",
    "\.16" -> "\\.16",
    "\.17" -> "\\.17",
    "\.18" -> "\\.18",
    "\.19" -> "\\.19",
    "\.1a" -> "\\.1a",
    "\[RawEscape]" -> "\\[RawEscape]",
    "\.1c" -> "\\.1c",
    "\.1d" -> "\\.1d",
    "\.1e" -> "\\.1e",
    "\.1f" -> "\\.1f",

    (*
    DEL
    *)
    "\.7f" -> "\\.7f",

    (*
    C1 block
    *)
    "\.80" -> "\\.80",
    "\.81" -> "\\.81",
    "\.82" -> "\\.82",
    "\.83" -> "\\.83",
    "\.84" -> "\\.84",
    "\.85" -> "\\.85",
    "\.86" -> "\\.86",
    "\.87" -> "\\.87",
    "\.88" -> "\\.88",
    "\.89" -> "\\.89",
    "\.8a" -> "\\.8a",
    "\.8b" -> "\\.8b",
    "\.8c" -> "\\.8c",
    "\.8d" -> "\\.8d",
    "\.8e" -> "\\.8e",
    "\.8f" -> "\\.8f",
    "\.90" -> "\\.90",
    "\.91" -> "\\.91",
    "\.92" -> "\\.92",
    "\.93" -> "\\.93",
    "\.94" -> "\\.94",
    "\.95" -> "\\.95",
    "\.96" -> "\\.96",
    "\.97" -> "\\.97",
    "\.98" -> "\\.98",
    "\.99" -> "\\.99",
    "\.9a" -> "\\.9a",
    "\.9b" -> "\\.9b",
    "\.9c" -> "\\.9c",
    "\.9d" -> "\\.9d",
    "\.9e" -> "\\.9e",
    "\.9f" -> "\\.9f"
  }]

replaceLinearSyntax[s_String] :=
  StringReplace[s, {
    "\!" -> "\\!",
    "\%" -> "\\%",
    "\&" -> "\\&",
    "\(" -> "\\(",
    "\)" -> "\\)",
    "\*" -> "\\*",
    "\+" -> "\\+",
    "\/" -> "\\/",
    "\@" -> "\\@",
    "\^" -> "\\^",
    "\_" -> "\\_",
    "\`" -> "\\`"
  }]


(* :!CodeAnalysis::EndBlock:: *)


reassembleEmbeddedLinearSyntax::unhandled = "Unbalanced openers and closers."

(*
Fix the terrible, terrible design mistake that prevents linear syntax embedded in strings from round-tripping

TODO: dump explanation about terrible, terrible design mistake here
*)
reassembleEmbeddedLinearSyntax[toks_] :=
Catch[
Module[{embeddedLinearSyntax, openerPoss, closerPoss},

  openerPoss = Position[toks, LeafNode[String, s_ /; StringCount[s, "\("] == 1 && StringCount[s, "\)"] == 0, _]];

  closerPoss = Position[toks,
    LeafNode[String, s_ /; StringCount[s, "\("] == 0 && StringCount[s, "\)"] == 1, _] |
      ErrorNode[Token`Error`UnterminatedString, s_ /; StringCount[s, "\("] == 0 && StringCount[s, "\)"] == 1, _]];

  If[Length[openerPoss] != Length[closerPoss],
    Message[reassembleEmbeddedLinearSyntax::unhandled];
    Throw[toks]
  ];

  Fold[
    Function[{toks1, span},
      embeddedLinearSyntax = LeafNode[String, StringJoin[#[[2]]& /@ Take[toks1, {span[[1, 1]], span[[2, 1]]}]], <||>];
      ReplacePart[Drop[toks1, {span[[1, 1]] + 1, span[[2, 1]]}], span[[1]] -> embeddedLinearSyntax]]
    ,
    toks
    ,
    Transpose[{openerPoss, closerPoss}] //Reverse
  ]
]]
