import {
    EditorView,
    Decoration,
    ViewPlugin,
    WidgetType,
    MatchDecorator
  } from "@codemirror/view";
  import { isCursorInside } from "./utils";
  
import {EditorState} from "@codemirror/state";

  import { BallancedMatchDecorator2 } from "./matcher";
  
  import { keymap } from "@codemirror/view";
   
  import { EditorSelection } from "@codemirror/state";
  
  import { Balanced } from "node-balanced";
  
  var compactCMEditor; 
  
  export function SqrtBoxWidget(viewEditor) {
    compactCMEditor = viewEditor;
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
            changes: { from, to, insert: "(*SqB[*)Sqrt[_](*]SqB*)" },
            range: EditorSelection.cursor(from)
          };
        }
        return {
          changes: { from, to, insert: "(*SqB[*)Sqrt["+prev+"](*]SqB*)" },
          range: EditorSelection.cursor(from)
        };
      });
  
      dispatch(
        state.update(changes, { scrollIntoView: true, userEvent: "input" })
      );
      return true;
    };
  }

  class EditorWidget {

    constructor(visibleValue, view, dom, sliceRanges, ref) {
      this.view = view;
      this.visibleValue = visibleValue;
      const self = this;
      this.sliceRanges = sliceRanges;

      this.length = visibleValue.str.length;

      console.log('creating InstanceWidget');

      //(self);

      this.editor = compactCMEditor({
        //slice SqB[...]
        doc: visibleValue.str.slice(...sliceRanges),
        parent: dom,
        update: (upd) => self.applyChanges(upd),
        eval: () => {
          view.viewState.state.config.eval();
        },
        evalNext: () => {
          view.viewState.state.config.evalNext();
        },
        extensions: [
          keymap.of([
            { key: "ArrowRight", run: function (editor, key) {  
              if (editor?.editorLastCursor === editor.state.selection.ranges[0].to) {
                view.dispatch({selection: {anchor: self.visibleValue.pos + self.visibleValue.length}});
                view.focus();

                editor.editorLastCursor = undefined;
                return;
              }
              editor.editorLastCursor = editor.state.selection.ranges[0].to;  
            } },   
            { key: "ArrowLeft", run: function (editor, key) {  
              if (editor?.editorLastCursor === editor.state.selection.ranges[0].to) {
                view.dispatch({selection: {anchor: self.visibleValue.pos}});
                view.focus();
                editor.editorLastCursor = undefined;
                return;
              }
              editor.editorLastCursor = editor.state.selection.ranges[0].to;  
            } }
          ])

 
        ]       
      });
    }

    applyChanges(update) {

      //const args = this.visibleValue.args;
      const data = update;

      //const old = this.visibleValue.str;
      
      //console.log(this.visibleValue.pos);
      const changes = {from: this.visibleValue.argsPos + 5, to: this.visibleValue.argsPos + this.length - 1, insert: data};
      console.log(this.visibleValue);
      //const changes = {from: this.visibleValue.argsPos + args[0], to: this.visibleValue.argsPos + args[0].from + args[0].body.length - 1, insert: data};
      //console.warn('changes will be applied to...');
      //console.log(this.view.viewState.state.doc.toString().slice(changes.from, changes.to));
      
      //this.visibleValue.args[0] = data;
      //this.visibleValue.str = data;
      //this.visibleValue.length = this.visibleValue.str.length;

      //console.log('insert change');
      //console.log(changes);
      //console.log({oldLength: this.length, newLength: (data.length + 6)});
      const delta = (data.length + 6) - this.length;
      this.length = this.length + delta;
      this.visibleValue.length = this.visibleValue.length + delta;
      this.visibleValue.str = "Sqrt["+data+"]"; //save internally
      
      this.view.dispatch({changes: changes});
    }


    update(visibleValue) {
      //console.log('Update instance: new ranges & arguments');
      if (this.visibleValue.str != visibleValue.str) {
        console.warn('Out of sync');

        //if changes occured outside the widget
        //rebuild an entire thing

        this.visibleValue = visibleValue;
        const sliceRanges = this.sliceRanges;
        const editor = this.editor;
        const self = this;
        const view = this.view;

  
        this.length = visibleValue.str.length;

        const newState = compactCMEditor.state({
          doc: visibleValue.str.slice(...sliceRanges),
          update: (upd) => self.applyChanges(upd),
          eval: () => {
            view.viewState.state.config.eval();
          },
          evalNext: () => {
            view.viewState.state.config.evalNext();
          },
          extensions: [
            keymap.of([
              { key: "ArrowRight", run: function (editor, key) {  
                if (editor?.editorLastCursor === editor.state.selection.ranges[0].to) {
                  view.dispatch({selection: {anchor: self.visibleValue.pos + self.visibleValue.length}});
                  view.focus();
  
                  editor.editorLastCursor = undefined;
                  return;
                }
                editor.editorLastCursor = editor.state.selection.ranges[0].to;  
              } },   
              { key: "ArrowLeft", run: function (editor, key) {  
                if (editor?.editorLastCursor === editor.state.selection.ranges[0].to) {
                  view.dispatch({selection: {anchor: self.visibleValue.pos}});
                  view.focus();
                  editor.editorLastCursor = undefined;
                  return;
                }
                editor.editorLastCursor = editor.state.selection.ranges[0].to;  
              } }
            ])
          ]             
        });
        
        editor.setState(newState);
        return;
      }
      
      this.visibleValue.pos = visibleValue.pos;
      this.visibleValue.argsPos = visibleValue.argsPos;
      //this.visibleValue.args = visibleValue.args;
    }

    destroy() {
      console.warn('destroy Instance of Widget!');
      this.editor.destroy();
    }
  }
  
  class Widget extends WidgetType {
    constructor(visibleValue, ref, view) {
      super();
      this.view = view;
      this.visibleValue = visibleValue;
      this.reference = ref;
      //console.log('construct');
    }

    eq(other) {
      return false;
      return this.visibleValue.str === other.visibleValue.str;
    }

    updateDOM(dom, view) {
      //console.log(this.visibleValue);
      //console.log(this);
      //console.log('update widget DOM');
      this.DOMElement = dom;
      dom.EditorWidget.update(this.visibleValue);

      return true
    }

    toDOM(view) {
      console.log('Create a new one!');

      let span = document.createElement("span");
      span.classList.add("sqroot");

      //console.log('Visible value:');
      //console.log(this.visibleValue);

      const self = this;
  
      const head = document.createElement("span");
      head.classList.add("radicand");
      
      span.EditorWidget = new EditorWidget(this.visibleValue, view, head, [5,-1], []);

      span.appendChild(head);


      
      this.reference.push({destroy: () => {
        self.destroy(span);
      }});      

      this.DOMElement = span;

      return span;
    }

    skipPosition(pos, oldPos, selected) {
      if (oldPos.from != oldPos.to || selected) return pos;

      if (pos.from - oldPos.from > 0) {
        this.DOMElement.EditorWidget.editor.dispatch({selection: {anchor: 0}});
        this.DOMElement.EditorWidget.editor.focus();
      } else {
        const editor = this.DOMElement.EditorWidget.editor;
        editor.dispatch({selection: {anchor: editor.state.doc.length}});
        editor.focus();
      }
      //this.DOMElement.EditorWidget.wantedPosition = pos;
      
  
      return oldPos;
    }
  
    ignoreEvent() {
      return true;
    }

    destroy(dom) {
      dom.EditorWidget.destroy();
    }
  }
  
  const matcher = (ref, view) => {
    return new BallancedMatchDecorator2({
      tag: 'SqB',
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
        //console.log('update Deco');
        //console.log(this.disposable );
        //console.warn(update);
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
          el.destroy();
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
  