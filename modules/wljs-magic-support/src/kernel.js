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
    dispose() {}
    constructor(parent, data) {
      let pre = document.createElement("pre");
      pre.textContent = data;
      pre.style.maxHeight = "600px";
      pre.style.overflowY = "scroll";
      pre.style.overflowX = "auto";
      pre.style.maxWidth = "calc(80vw - var(--system-main-padding-left))";
      pre.classList.add('text-sm');
      parent.element.appendChild(pre);
      
      return this;
    }
}
  
window.SupportedCells['fileprint'] = {
    view: FileOutputCell
};
