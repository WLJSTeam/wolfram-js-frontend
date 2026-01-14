class ImageCell {
    dispose() {
      
    }
    
    constructor(parent, data) {
      let elt = document.createElement("div");
    
      elt.classList.add("frontend-object");
      elt.style.display = 'block';
      parent.element.appendChild(elt);  
      parent.element.classList.add('padding-fix');
  
      let img = document.createElement("img");
      
      img.src = data+'?noCache='+String(Math.floor(Math.random() * 1000));
      elt.appendChild(img);  
      
      return this;
    }
  }
  
window.SupportedCells['image'] = {
  view: ImageCell
};



class FileOutputCell {
    dispose() {
      
    }
    
    constructor(parent, data) {
      const {EditorView, EditorState, defaultHighlightStyle, syntaxHighlighting, editorCustomTheme} = window.SupportedCells['codemirror'].context;

    
      const editor = new EditorView({
        doc: data,
        extensions: [
          EditorState.readOnly.of(true),
          syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
          editorCustomTheme
        ],
        parent: parent.element
      }); 
      
      return this;
    }
  }
  
  window.SupportedCells['fileprint'] = {
    view: FileOutputCell
  };
