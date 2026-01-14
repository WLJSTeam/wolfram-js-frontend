
  import {Marked, Renderer} from 'marked';
  import katex from 'katex';
  import autorender from './../libs/auto-render/auto-render'

  const markedLoader = async (self) => {
    self["default"] = Marked;
    self["Renderer"] = Renderer;
  }


  const katexLoader = async (self) => {
    self["default"] = katex;
    self["autorender"] = autorender;
  }  

  new interpretate.shared(
    "katex",
    katexLoader
  );  

  new interpretate.shared(
    "Marked",
    markedLoader
  );    
