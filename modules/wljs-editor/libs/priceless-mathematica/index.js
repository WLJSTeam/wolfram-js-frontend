import { minimalSetup, EditorView } from "codemirror";

import { keymap } from "@codemirror/view";

import { wolframLanguage } from "./src/mathematica/mathematica";

import { SqrtBoxWidget } from "./src/boxes/sqrtbox";
import { FractionBoxWidget } from "./src/boxes/fractionbox";
import { SubscriptBoxWidget } from "./src/boxes/subscriptbox";
import { SupscriptBoxWidget } from "./src/boxes/supscriptbox";
import { GridBoxWidget } from "./src/boxes/gridbox";

import { Greekholder, Arrowholder } from "./src/sugar/misc";
 
import { bracketMatching } from "@codemirror/language"

import rainbowBrackets from 'rainbowbrackets'


let editorCustomTheme = EditorView.theme({
  "&.cm-focused": {
    outline: "dotted 1px black",
    background: 'inherit'
  },
  ".cm-line": {
    padding: 0,
    'padding-left': '2px',
    'align-items': 'center'
  },
  ".cm-activeLine": {
    'background-color': 'transparent'
  }
});

let editorCustomThemeCompact = EditorView.theme({
  "&.cm-focused": {
    outline: "dotted 1px black",
    background: 'inherit'
  },
  ".cm-line": {
    padding: 0,
    'padding-left': '2px',
    'align-items': 'center'
  },
  ".cm-activeLine": {
    'background-color': 'transparent'
  },
  ".cm-scroller": {
    'line-height': 'inherit',
    'overflow-x': 'overlay',
    'overflow-y': 'overlay',
    'align-items': 'initial',
    'min-height': '3pt',
    'min-width': '3pt'
  },
  ".cm-content": {
    "padding": '0px 0',
    "overflow": 'overlay'
  }
});

let doc = ` 
(*GB[*){{1(*|*),(*|*)0}(*||*),(*||*){0(*|*),(*|*)1}}(*]GB*)
`;



let compactWLEditor = null;


compactWLEditor = (p) => {
  let editor = new EditorView({
    doc: p.doc,
    extensions: [
      keymap.of([
        { key: "Enter", preventDefault: true, run: function (editor, key) { 
          return true;
        } }
      ]),  
      keymap.of([
        { key: "Shift-Enter", preventDefault: true, run: function (editor, key) { 
          p.eval();
          return true;
        } }
      ]),  
      p.extensions || [],       
      minimalSetup,
      editorCustomThemeCompact,      
      wolframLanguage, 
      SqrtBoxWidget(compactWLEditor),
      FractionBoxWidget(compactWLEditor),
      SubscriptBoxWidget(compactWLEditor),
      SupscriptBoxWidget(compactWLEditor),
      GridBoxWidget(compactWLEditor),
     // bracketMatching(),
      rainbowBrackets(),
      Greekholder,
      Arrowholder,
      EditorView.updateListener.of((v) => {
        if (v.docChanged) {
          p.update(v.state.doc.toString());
        }
      })
    ],
    
    parent: p.parent
  });
  
  editor.viewState.state.config.eval = p.eval;


  return editor;
}

let mainEditor = new EditorView({
  doc: doc,
  extensions: [
    minimalSetup,
    editorCustomTheme,   
    wolframLanguage, 
    SqrtBoxWidget(compactWLEditor),
    FractionBoxWidget(compactWLEditor),
    SubscriptBoxWidget(compactWLEditor),
    SupscriptBoxWidget(compactWLEditor),
    GridBoxWidget(compactWLEditor),
   // bracketMatching(),
    rainbowBrackets(),
    Greekholder,
    Arrowholder
  ],
  parent: document.querySelector("#editor")
});

mainEditor.viewState.state.config.eval = function() {alert('eval')};
