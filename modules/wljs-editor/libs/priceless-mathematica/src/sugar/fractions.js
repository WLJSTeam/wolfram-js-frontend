import {
  EditorView,
  Decoration,
  ViewPlugin,
  WidgetType,
  MatchDecorator
} from "@codemirror/view";
import { isCursorInside } from "./utils";

import { BallancedMatchDecorator } from "./matcher";

import { keymap } from "@codemirror/view";
 
import { EditorSelection } from "@codemirror/state";

var subEditor; 

import { Balanced } from "node-balanced";

const validator = new Balanced({
  open: ['{', '[', '('],
  close: ['}', ']', ')'],
  balance: true
});

export function fractionsWidget(view) {
  subEditor = view;
  return [
    //mathematicaMathDecoration,
    placeholder,
    keymap.of([{ key: "Ctrl-/", run: snippet() }])
  ];
}

function snippet() {
  return ({ state, dispatch }) => {
    if (state.readOnly) return false;
    let changes = state.changeByRange((range) => {
      let { from, to } = range;
      //if (atEof) from = to = (to <= line.to ? line : state.doc.lineAt(to)).to
      const prev = state.sliceDoc(from, to);
      if (prev.length === 0) {
        return {
          changes: { from, to, insert: "CM6Fraction[_,_]" },
          range: EditorSelection.cursor(from)
        };
      }
      return {
        changes: { from, to, insert: "CM6Fraction[" + prev + ", _]" },
        range: EditorSelection.cursor(from)
      };
    });

    dispatch(
      state.update(changes, { scrollIntoView: true, userEvent: "input" })
    );
    return true;
  };
}

class Widget extends WidgetType {
  constructor(visibleValue, ref, view) {
    super();
    this.view = view;
    this.visibleValue = visibleValue;
    this.ref = ref;
    this.subEditor = subEditor;
  }
  eq(other) {
    //console.log('compare');
    //console.log(this.visibleValue.str === other.visibleValue.str)
    return this.visibleValue.str === other.visibleValue.str;
  }
  updateDOM(dom, view) {
    //console.log('update widget DOM');
    return true
  }
  toDOM(view) {
    let span = document.createElement("span");
    span.classList.add('fraction');

    //console.log(this.visibleValue.args);

    if (this.visibleValue.args.length !== 2) {
      this.visibleValue.args = ["_", "_"];
      console.error("argumets doesnt match");
    }
    //console.log('create widget DOM!!!!');
    //console.log(this.visibleValue);
 
    const args = this.visibleValue.args;

    const table      = document.createElement("table");
    table.classList.add('container');
    span.appendChild(table);
    
    const tbody      = document.createElement("tbody");
    table.appendChild(tbody);

    const tre        = document.createElement("tr");
    const trd        = document.createElement("tr");
    tbody.appendChild(tre);
    tbody.appendChild(trd);

    const enumenator  = document.createElement("td");
    enumenator.classList.add('enumenator');
    tre.appendChild(enumenator);

    const denumenator = document.createElement("td");
    trd.appendChild(denumenator);

    
    const visibleValue = this.visibleValue;
    //const view = this.view;
    const recreateString = (args) => {
      this.visibleValue.str =  'CM6Fraction['+args[0]+', '+args[1]+']';
      const changes = {from: visibleValue.pos, to: visibleValue.pos + visibleValue.length, insert: this.visibleValue.str};
      this.visibleValue.length = this.visibleValue.str.length;

      return changes;
    }

    let topEditor, bottomEditor;
    const origin = view;

    topEditor = this.subEditor({
      doc: args[0],
      parent: enumenator,
      update: (upd) => {
        const valid = validator.matchContentsInBetweenBrackets(upd, []);
        if (!valid) return;

        this.visibleValue.args[0] = upd;
        const change = recreateString(this.visibleValue.args);
        //console.log('insert change');
        //console.log(change);
        view.dispatch({changes: change});
      },
      eval: () => {
        view.viewState.state.config.eval();
      },
      extensions: [
        keymap.of([
          { key: "ArrowLeft", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              origin.focus()
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } }, 
          { key: "ArrowRight", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              origin.focus()
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } },             
          { key: "ArrowDown", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              bottomEditor.focus();
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } }
        ])
      ]
    });

    bottomEditor = this.subEditor({
      doc: args[1],
      parent: denumenator,
      update: (upd) => {
        const valid = validator.matchContentsInBetweenBrackets(upd, []);
        if (!valid) return;

        this.visibleValue.args[1] = upd;
        const change = recreateString(this.visibleValue.args);
        //console.log('insert change');
        //console.log(change);
        view.dispatch({changes: change});
      },
      eval: () => {
        view.viewState.state.config.eval();
      },
      extensions: [
        keymap.of([
          { key: "ArrowLeft", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              origin.focus()
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } }, 
          { key: "ArrowRight", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              origin.focus()
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } },             
          { key: "ArrowUp", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              topEditor.focus();
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } }
        ])
      ]  
    });


    return span;
  }

  ignoreEvent() {
    return true;
  }
}

const matcher = (ref, view) => {
  return new BallancedMatchDecorator({
    regexp: /CM6Fraction\[/,
    decoration: (match) => {
      return Decoration.replace({
        widget: new Widget(match, ref, view)
      });
    }
  });
};

const placeholder = ViewPlugin.fromClass(
  class {
    constructor(view) {
      this.disposable = [];
      this.placeholder = matcher(this.disposable, view).createDeco(view);
    }
    update(update) {
      if (update.docChanged || update.selectionSet || update.viewportChanged) {
        //console.log('check the cursor7!'); 
        //console.log(update.state.selection.ranges[0].from);
        //console.log(this.placeholder.chunk[0].from);
      }

      this.placeholder = matcher(this.disposable, update).updateDeco(
        update,
        this.placeholder
      );
    }
    destroy() {
      //console.log("removed holder");
      //console.log("disposable");
      //console.log(this.disposable);
      this.disposable.forEach((el) => {
        el.dispose();
      });
    }
  },
  {
    decorations: (instance) => instance.placeholder,
    provide: (plugin) =>
      EditorView.atomicRanges.of((view) => {
        var _a;
        
        return (
          ((_a = view.plugin(plugin)) === null || _a === void 0
            ? void 0
            : _a.placeholder) || Decoration.none
        );
      })
  }
);
