function __isElement(element) {
    return element instanceof Element || element instanceof HTMLDocument;  
  }

const codemirror = window.SupportedCells['codemirror'].context;  
  
class ScopedEval {
  ondestroy = function() {}
  after = function() {}
  error  = false
    
  constructor(scope, script, asyncQ = false) {
    if (asyncQ) {
      this.script = '(async (g0this) => {'+ script + '})(this)';
      this.asyncQ = new Deferred();
      const copy = this.asyncQ;
      this.return = (object) => copy.resolve(object);
    } else {
      this.script = '(() => {'+ script + '})()';
    }

    return this;
  }
    
  eval() {
    const self = this;
    //console.warn(self);

    try {

      if (self.asyncQ) {
        eval(self.script);
        
        return self.asyncQ.promise;
      }

      return eval(self.script);
    } catch(err) {
      self.error = err;
      if (self.asyncQ) {
        self.asyncQ.resolve();
        return self.asyncQ.promise;
      }
    }
  }
} 

class JSCell {
    scope = {}
    createScopedEval = (scope, script) => {return({
      ondestroy: function() {},
      after: function() {},
      result: Function(`${script}`)
    })}  
    
    dispose() {
      this.scope.ondestroy();
    }
    
    constructor(parent, data) {
      this.origin = parent;
      this.scope = new ScopedEval({}, data)
      
      const result = this.scope.eval();

      if (this.scope.error) {
        const errorDiv = document.createElement('div');
        errorDiv.innerText = this.scope.error;
        errorDiv.classList.add('err-js');
        this.origin.element.appendChild(errorDiv);
        return this;
      }

      if (__isElement(result)) {
        this.origin.element.appendChild(result);
        this.scope.after(result);
        return this;
      }
      
      const outputDom = document.createElement('div');
      outputDom.innerText = String(result);
      outputDom.classList.add('text-sm');

      this.origin.element.appendChild(outputDom);
      this.scope.after(outputDom);
      
      return this;
    }
  }
  
  window.SupportedLanguages.push({
    check: (r) => {return(r[0].match(/\w*\.(js|esm)$/) != null)},
    plugins: [codemirror.javascript(), codemirror.EditorView.editorAttributes.of({class: 'clang-js'})],
    name: codemirror.javascriptLanguage.name
  });

  window.SupportedCells['js'] = {
    view: JSCell
  };

  class ESMCell {
    scope = {}
    createScopedEval = (scope, script) => {return({
      ondestroy: function() {},
      after: function() {},
      result: Function(`${script}`)
    })}  
    
    dispose() {
      this.scope.ondestroy();
    }
    
    constructor(parent, data) {
      this.origin = parent;
      this.scope = new ScopedEval({}, data, true);

      const self = this;
      
      this.scope.eval().then((result) => {
        if (self.scope.error) {
          const errorDiv = document.createElement('div');
          errorDiv.innerText = self.scope.error;
          errorDiv.classList.add('err-js');
          self.origin.element.appendChild(errorDiv);
          return;
        }

        if (__isElement(result)) {
          self.origin.element.appendChild(result);
          self.scope.after(result);
          return;
        }

        const outputDom = document.createElement('div');
        outputDom.innerText = String(result);
        outputDom.classList.add('text-sm');
  
        self.origin.element.appendChild(outputDom);
        self.scope.after(outputDom);        
      });

      return this;
    }
  }  
    
  window.SupportedCells['esm'] = {
    view: ESMCell
  };
