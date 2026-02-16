const codemirror = window.SupportedCells['codemirror'].context;

let timeout = false;

core.UIAutocompleteConnect = async (args, env) => {
    console.log('Autocomplete connected to a server');
    core.UIAutocompleteExtend.symbols = new Set();
    
    const hash = await interpretate(args[0], env);
    //const channel = await interpretate(args[1], env);

    //check the store
    if (localStorage.getItem("codemirror-autocomplete-hash") != String(hash)) {
      let completeInfo = await server.ask('CoffeeLiqueur`Extensions`Autocomplete`Private`GetDefaults');
      completeInfo = await interpretate(completeInfo, env);
      console.warn('Update static autocomplete info');
      console.warn(completeInfo);
      localStorage.setItem("codemirror-autocomplete-hash", String(completeInfo.hash));
      localStorage.setItem("codemirror-autocomplete", JSON.stringify(completeInfo.data));
      codemirror.EditorAutocomplete.replaceAll(completeInfo.data);
    } else {
      codemirror.EditorAutocomplete.replaceAll(JSON.parse(localStorage.getItem("codemirror-autocomplete")));
    }
    
    server.kernel.emitt('autocomplete', 'True', 'Connect');
}

core['CoffeeLiqueur`Extensions`FileEditor`WL`Internal`UIAutocompleteActivate'] = async (args, env) => {
    codemirror.EditorAutocomplete.replaceAll(JSON.parse(localStorage.getItem("codemirror-autocomplete")));
}

core.UIAutocompleteExtend = async (args, env) => {
    

    const data = await interpretate(args[0], env);
    console.log('Autocomplete populate with ' + data.length + ' symbols');
    
    
    data.forEach((element)=>{
      const name = element[0];
      const usage = element[1];
  
      if (!core.UIAutocompleteExtend.symbols.has(name)) {
        codemirror.EditorAutocomplete.extend([  
          {
              "label": name,
              "type": usage == "User's defined symbol" ? "variable" : "keyword",
              "info": usage,
              "c": true
          }]);
  
        core.UIAutocompleteExtend.symbols.add(name);
      }
    });

    codemirror.EditorAutocomplete.refresh();
}

core["CoffeeLiqueur`Extensions`Autocomplete`UIAutocompleteExtend"] = core.UIAutocompleteExtend


core.UIAutocompleteExtend.symbols = new Set();