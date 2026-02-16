function unicodeToChar(text) {
    return text.replace(/\\:[\da-f]{4}/gi, 
           function (match) {
                return String.fromCharCode(parseInt(match.replace(/\\:/g, ''), 16));
           });
  }

class SystemPrintCells {
    global = {};

    dispose() {
      if (this.global.stack) {
        for (const obj of Object.values(this.global.stack))  {
          obj.dispose();
        }
      }
    }
    
    constructor(parent, data) {
      let elt = document.createElement("div");
      const uid = parent.uid;
      
      elt.classList.add('text-sm', 'ml-0.5', 'text-gray-500');
      elt.style.display = "block";
      
      parent.element.appendChild(elt);
      parent.element.classList.add('padding-fix');
      let str = data;

      if (RegExp(/\(\*/gm).exec(str)) {
        //spawn a code editor
        console.log({str});
        interpretate(['EditorView', ['JSObject', str]], {global: this.global, element: elt}).then((succs) => {}, (reject) => {
          elt.innerText = reject;
        });

        return this;
      } 

      if (str.charAt(0) === '"') {
        str = str.slice(1,-1);
      }

      elt.innerText = unicodeToChar(str);
      
      return this;
    }
  }
  
  window.SupportedCells['print'] = {
    view: SystemPrintCells
  };