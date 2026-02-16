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

import { Balanced } from "node-balanced";

const validator = new Balanced({
  open: ['{', '[', '('],
  close: ['}', ']', ')'],
  balance: true
});

var subEditor; 

export function squareRootWidget(view) {
  subEditor = view;
  return [
    //mathematicaMathDecoration,
    placeholder,
    keymap.of([{ key: "Ctrl-2", run: snippet() }])
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
          changes: { from, to, insert: "CM6Sqrt[_]" },
          range: EditorSelection.cursor(from)
        };
      }
      return {
        changes: { from, to, insert: "CM6Sqrt[" + prev + "]" },
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
    
    return this.visibleValue.str === other.visibleValue.str;
  }
  updateDOM(dom, view) {
    //console.log('update widget DOM');
    return true
  }
  toDOM(view) {
    let span = document.createElement("span");
    span.classList.add("sqroot");

    if (this.visibleValue.args.length !== 1) {
      this.visibleValue.args = [this.visibleValue.str];
      //console.log("single argument or not found");
    }
    
    //console.log('create widget DOM!!!!');
    //console.log(this.visibleValue);
 
    const args = this.visibleValue.args;

    const head = document.createElement("span");
    head.classList.add("radicand");
    
    const visibleValue = this.visibleValue;
    
    const recreateString = (args) => {
      this.visibleValue.str =  'CM6Sqrt['+args[0]+']';
      const changes = {from: visibleValue.pos, to: visibleValue.pos + visibleValue.length, insert: this.visibleValue.str};
      this.visibleValue.length = this.visibleValue.str.length;

      return changes;
    }

    const origin = view;

    this.subEditor({
      doc: args[0],
      parent: head,
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
          { key: "ArrowRight", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              origin.focus()
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } },   
          { key: "ArrowLeft", run: function (editor, key) {  
            if (editor?.editorLastCursor === editor.state.selection.ranges[0].to)
              origin.focus()
            editor.editorLastCursor = editor.state.selection.ranges[0].to;  
          } }
        ])
      ]       
    });

    span.appendChild(head);

    //span.classList.add("cm-bold");*/
    return span;
  }

  ignoreEvent() {
    return true;
  }
}

const matcher = (ref, view) => {
  return new BallancedMatchDecorator({
    regexp: /CM6Sqrt\[/,
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
