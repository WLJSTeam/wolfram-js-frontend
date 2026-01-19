function jsonStringifyRecursive(obj) {
  const cache = new Set();
  return JSON.stringify(obj, (key, value) => {
      if (typeof value === 'object' && value !== null) {
          if (cache.has(value)) {
              // Circular reference found, discard key
              return;
          }
          // Store value in our collection
          cache.add(value);
      }
      return value;
  }, 4);
}

//default plug for a server object
window.server = undefined;

interpretate.anonymous = async (d, org) => {
  //TODO Check if it set delayed or set... if set, then one need only to cache it
  console.log('Anonimous symbol: ' + JSON.stringify(d));  

  let name;
  //check it is a plain symbol
  if (d instanceof Array) {
    //console.error('stack call: ');
    //console.error(jsonStringifyRecursive(org.global.stack));
    throw(d[0] + ' is not defined on frontend');
  } else {
    name = d;   //symbol
  }

  let data;
  let packed = false;

  //request it from the server
  console.log('sending request to a server... for'+name);
  if (!server || !server?.kernel) {
    console.log('no evaluation kernel available, trying master...');
    data = await server.getSymbol(name); //get the data
  } else {
    if (!server.kernel.connected) {
      console.log('no evaluation connected kernel available, trying master...');
      data = await server.getSymbol(name); //get the data
    } else {
      console.log('fetching from evaluation kernel');
      data = await server.kernel.getSymbol(name); //get the data
    }
  }
  console.log('got');
  //console.log(data);
  
  //check for strings 
  let symbolQ = typeof data === 'string';

  if (symbolQ) {
    if (data.charAt(0) == "'") symbolQ = false;
    if (isNumeric(data)) symbolQ = false;
  }

  //if it is a shit
  if ((symbolQ && !(data in core)) || typeof data == 'undefined') {
    console.log('checking... '+name);
    console.log('recived data..');
    console.log(jsonStringifyRecursive(data));
    //console.error('stack call: ');
    //console.error(jsonStringifyRecursive(org.global.stack));
    throw('symbol '+data+' is not defined in any contextes and packing on frontend'); 
  }

  //if it is OK
  if (name in core) {
    //already requested
    console.log('it was already requested');
    return interpretate(d, org);
  }

  core[name] = async (args, env) => {
    //console.log('IE: calling our symbol...');
    //evaluate in the context
    const data = await interpretate(core[name].data, env);

    if (env.root && !env.novirtual) core[name].instances[env.root.uid] = env.root; //if it was evaluated insdide the container, then, add it to the tracking list
    //if (env.hold) return ['JSObject', core[name].data];

    return data;
  }

  core[name].update = async (args, env) => {
    //evaluate in the context

    //cache good for numerics
    if (env.useCache) {
      if (!core[name].cached || core[name].currentData != core[name].data) {
        core[name].cached = await interpretate(core[name].data, env);
        core[name].currentData = core[name].data; //just copy the reference
        //console.log('cache miss');
      } 

      return core[name].cached;
    }

    const data = await interpretate(core[name].data, env);
    //if (env.hold) return ['JSObject', data];
    return data;
  }  

  core[name].destroy = async (args, env) => {

    delete core[name].instances[env.root.uid];
    //console.warn(env.root.uid + ' was destroyed')
    //console.warn('external symbol was destoryed');
  }  

  core[name].data = data; //get the data

  server.kernel.addTracker(name);
  server.kernel.trackedSymbols[name] = true;

  core[name].virtual = true;
  core[name].instances = {};

  //interpretate it AGAIN!
  return interpretate(d, org);
}

core.Offload = (args, env) => {
  if (args.length > 1) {
      //alternative path - checking options
      //do it in ugly superfast way
      if (args[1][1] === "'Static'") {
          if (args[1][2] && args[1][2] != 'False') {
              return interpretate(args[0], {...env, static: true});
          }
      } else if (args.length > 2) {
          if (args[2][1] === "'Static'") {
              if (args[2][2] && args[2][2] != 'False') {
                  return interpretate(args[0], {...env, static: true});
              }                
          }
      }
  }

  return interpretate(args[0], env);
}

core.Offload.update = (args, env) => {
  
  if (args.length > 1) {
      //alternative path - checking options
      //do it in ugly superfast way

      //Volitile -> False -> Reject updates

      //low-level optimizations, we dont' need to spend time on parsing options
      
      if (args[1][1] === "'Volatile'") {
          if (!args[1][2] || args[1][2] != 'True') {
              console.log('Update was rejected (Nonvolatile)');
              return;
          }
      } else if (args.length > 2) {
 
          if (args[2][1] === "'Volatile'") {
              if (!args[2][2] || args[2][2] != 'True') {
                  console.log('Update was rejected (Nonvolatile)');
                  return;
              }                
          }
      }
  }

  return interpretate(args[0], env);
}

//a default fallback!!!
core.FrontEndVirtual = async (args, env) => {
  const copy = {...env};
  const store = args[0];
  const instance = new ExecutableObject('fevirtual-fallback-'+uuidv4(), copy, store);
  instance.assignScope(copy);


  return await instance.execute();
}

core.Offload.destroy = (args, env) => {
  return interpretate(args[0], env);
}
