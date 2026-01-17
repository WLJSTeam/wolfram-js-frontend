let count = 0;



class WLXCell {
    envs = []

    static dispose (envs) {
      for (const env of envs) {
        for (const obj of Object.values(env.global.stack))  {
          console.log('dispose');
          obj.dispose();
        }
      }
    }
    static async hydrate (data, envs, setContent) {
         let string = data;
          count++;
    
          const r = {
            fe: new RegExp(/FrontEndExecutable\[([^\[|\]]+)\]/g),
            feh: new RegExp(/FrontEndExecutableHold\[([^\[|\]]+)\]/g)
          };

          const fe = [];
        
          const feReplacer = (fe, offset=0) => {
            return function (match, index) {
              const uid = match.slice(19 + offset,-1);
              count++;
              fe.push([uid, count]);
              return `<div id="wlx-${count}-${uid}" class="wlx-frontend-object"></div>`;
            }
          } 
        
          //extract FE objects
          string = string.replace(r.fe, feReplacer(fe));
          string = string.replace(r.feh, feReplacer(fe, 4));
        
          await setContent(string);
          

          for (const o of fe) {
              const uid = o[0];
              const c   = o[1];
            
              const cuid = Date.now() + Math.floor(Math.random() * 10009);
              var global = {call: cuid};
            
              let env = {global: global, element: document.getElementById(`wlx-${c}-${uid}`)}; 
              console.log("WLX: creating an object with key ");
            
            
              console.log('forntend executable');
            
              let obj;
              console.log('check cache');
              if (ObjectHashMap[uid]) {
                  obj = ObjectHashMap[uid];
              } else {
                  obj = new ObjectStorage(uid);
              }
              console.log(obj);
            
              const copy = env;
              const store = await obj.get();
              const instance = new ExecutableObject('wlx-static-'+uuidv4(), copy, store, true);
              instance.assignScope(copy);
              obj.assign(instance);
            
              instance.execute();          
            
              envs.push(env);          
          };
    }

    dispose() {
      console.warn('WLX cell dispose...');
      WLXCell.dispose(this.envs);
    }
    
    constructor(parent, data) {
      WLXCell.hydrate(data, this.envs, async (content) => {
        setInnerHTML(parent.element, content);
        return;
      });
      parent.element.classList.add('padding-fix');
      return this;
    }
  }

  const codemirror = window.SupportedCells['codemirror'].context; 
  
  window.SupportedLanguages.push({
    check: (r) => {return(r[0] === '.wlx')},
    plugins: [codemirror.html(), codemirror.EditorView.editorAttributes.of({class: 'clang-wlx'})],
    name: codemirror.htmlLanguage.name
  });

  window.SupportedCells['wlx'] = {
    view: WLXCell
  };

  const dd = async (args, env) => {
    const uid = await interpretate(args[0], env);
    if (dd.envs[uid]) for (const obj of Object.values(dd.envs[uid].global.stack))  {
      console.log('dispose wlx object');
      obj.dispose();
    }
  }
  dd.envs = {};
  dd.bindEnv = (env, id) => {dd.envs[id] = env};
  core['CoffeeLiqueur`Extensions`WLXCells`Private`dispose'] = dd;

