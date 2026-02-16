function s(o, r, e = void 0) {
    let n = () => {
    };
    return (...t) => (n(), new Promise((c, i) => {
      const u = setTimeout(() => c(o(...t)), r);
      n = () => {
        clearTimeout(u), e !== void 0 && i(e);
      };
    }));
  }

var f = Object.defineProperty;
var d = (t, n, e) => n in t ? f(t, n, { enumerable: !0, configurable: !0, writable: !0, value: e }) : t[n] = e;
var r = (t, n, e) => (d(t, typeof n != "symbol" ? n + "" : n, e), e);


const codemirror$1 = window.SupportedCells['codemirror'].context; 

const a = codemirror$1.ViewPlugin;
const c = codemirror$1.Decoration;
const m = codemirror$1.keymap;
const h = codemirror$1.WidgetType;
const p = codemirror$1.StateField;
const S = codemirror$1.StateEffect;
const y = codemirror$1.Prec;
const g = codemirror$1.EditorSelection;

const u = p.define({
  create() {
    return { suggestion: null };
  },
  update(t, n) {
    const e = n.effects.find(
      (s) => s.is(l)
    );
    return n.state.doc && e && n.state.doc == e.value.doc ? { suggestion: e.value.text } : { suggestion: null };
  }
}), l = S.define();
function w(t, n) {
  const e = t.state.selection.main.head, s = [], i = c.widget({
    widget: new x(n),
    side: 1
  });
  return s.push(i.range(e)), c.set(s);
}
class x extends h {
  constructor(e) {
    super();
    r(this, "suggestion");
    this.suggestion = e;
  }
  toDOM() {
    const e = document.createElement("span");
    return e.style.opacity = "0.4", e.className = "cm-inline-suggestion", e.textContent = this.suggestion, e;
  }
  get lineBreaks() {
    return this.suggestion.split(`
`).length - 1;
  }
}
const C = (t) => a.fromClass(
  class {
    async update(e, view) {
      const s = e.state.doc;
      if (!e.docChanged)
        return;
      const i = await t(e.state, view);
      if (!i) return;

      e.view.dispatch({
        effects: l.of({ text: i, doc: s })
      });
    }
  }
), D = a.fromClass(
  class {
    constructor() {
      r(this, "decorations");
      this.decorations = c.none;
    }
    update(n) {
      var s;
      const e = (s = n.state.field(
        u
      )) == null ? void 0 : s.suggestion;
      if (!e) {
        this.decorations = c.none;
        return;
      }
      this.decorations = w(
        n.view,
        e
      );
    }
  },
  {
    decorations: (t) => t.decorations
  }
), E = y.highest(
  m.of([
    {
      key: "Tab",
      run: (t) => {
        const state = t.state;
        const main = state.selection.main;
        const suggestion = state.field(u)?.suggestion;
        if (!suggestion) return false;

        // compute end-of-line from the cursor
        const lineEnd = state.doc.lineAt(main.head).to;

        t.dispatch({
          ...T(state, suggestion, main.head, lineEnd) // <-- replace [head, lineEnd]
        });
        return true;
      }
    }
  ])
);
function T(t, n, e, s) {
  return {
    ...t.changeByRange((i) => {
      if (i == t.selection.main)
        return {
          changes: { from: e, to: s, insert: n },
          range: g.cursor(e + n.length)
        };
      const o = s - e;
      return !i.empty || o && t.sliceDoc(i.from - o, i.from) != t.sliceDoc(e, s) ? { range: i } : {
        changes: { from: i.from - o, to: i.from, insert: n },
        range: g.cursor(i.from - o + n.length)
      };
    }),
    userEvent: "input.complete"
  };
}
function W(t) {
  const { delay: n = 500 } = t, e = s(t.fetchFn, n);
  return [
    u,
    C(e),
    D,
    E
  ];
}

const codemirror = window.SupportedCells['codemirror'].context; 
const originFacet = codemirror.originFacet;

const fetchSuggestion = async (state, view) => {
    // or make an async API call here based on editor state
    const cell = state.facet(originFacet)[0].origin;
    const cursor = state.selection.ranges[0];

    
    const result = await server.io.fetch('CoffeeLiqueur`Extensions`CommandPalette`AI`Autocomplete`Private`gen', [cursor.from+1, cursor.to+1, cell.uid ]);
    if (!result) return false;

    return result.slice(1, -1);
};

codemirror.EditorExtensions.push(() => {
    return W({
        fetchFn: fetchSuggestion,
        delay: codemirror.llmCompletionDelay || 400,
      });
});
