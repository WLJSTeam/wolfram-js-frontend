//helps to find instance from server
const MetaMarkers = {};

//DEPRICATED!!!
//DEPRICATED!!!

core.MetaMarker = async (args, env) => {
  if (env.hold) {
    console.log('Held meta-marker expression!');
    return ["MetaMarker", ...args];
  }

  const marker = await interpretate(args[0], env);

  //an exception if no instance provided
  if (!env.root) {
    console.log('NO instance provided!!!');
    console.log('Attaching env only');

    MetaMarkers[marker] = {
      noInstanceQ: true,
      env: env
    };

    return null;
  }


  const inst = env.root.instance;

  console.log('instance '+inst+'is marked as '+marker);
  if (marker in MetaMarkers) {
    MetaMarkers[marker][inst] = env;
  } else {
    MetaMarkers[marker] = {};
    MetaMarkers[marker][inst] = env;
  }


  return null;
}

//DEPRICATED!!!//DEPRICATED!!!

core.MetaMarker.update = (args, env) => {
  //void
}

//DEPRICATED!!!//DEPRICATED!!!
//DEPRICATED!!!//DEPRICATED!!!

core.MetaMarker.destroy = async (args, env) => {
  const marker = await interpretate(args[0], env);
  console.log('dispose marker for instance '+env.root.instance);
  //console.log('in the context');
  //console.log(env);
  //console.log(MetaMarkers[marker]);

  delete MetaMarkers[marker][env.root.instance];
}  

core.FindMetaMarker = async (args, env) => {
  const marker = await interpretate(args[0], env);

  if (marker in MetaMarkers) {
    console.log('found one!');
    const arr =  Object.values(MetaMarkers[marker]);
    const list = arr.map((el) => {
      return ['MetaMarkers', el]
    });

    //console.log('list of markers');
    //console.log(list);

    return list;
  }

  return null;
}

//DEPRICATED!!!//DEPRICATED!!!

const instancesGroups = {};

core.FrontEndInstanceGroup = async (args, env) => {
  const before = Object.keys(env.global.stack);

  const uid = await interpretate(args[1], env);
  const result = await interpretate(args[0], env);

  const after = Object.keys(env.global.stack);

  instancesGroups[uid] = after.filter(x => !before.includes(x)).map((e)=>env.global.stack[e]);
  

  return result;
}

//DEPRICATED!!!//DEPRICATED!!!

core.FrontEndInstanceGroupDestroy = async (args, env) => {
  const uid = await interpretate(args[0], env); 
  instancesGroups[uid].forEach((el) => {
    el.dispose();
  });

  delete instancesGroups[uid];
}

//DEPRICATED!!!//DEPRICATED!!!

core.MarkerContainer = async (args, env) => {
    const expr = args[0];
    const marker = await interpretate(args[1], {...env, hold:true});

    if (marker[0] !== 'MetaMarker') 
        throw 'Last argument is not a MetaMarker object!';
    
    const uid = await interpretate(marker[1], env);
    const results = [];

    if (uid in MetaMarkers) {
      console.log('found Marker');

      if (MetaMarkers[uid].noInstanceQ) {
        console.log('plain env. No instance specified');
        //execute inside given env
        console.log('try!');

        const copy = {...MetaMarkers[uid].env};
  
        //merge the scope
        copy.scope = {...copy.scope, ...env.scope};

        const result = await interpretate(expr, copy);
        results.push(result);

        return results;
      }

      const arr =  Object.values(MetaMarkers[uid]);
      
      for (const instance of arr) {

        //execute inside the container
        console.log('try!');

        if (instance.root.dead) {
          console.log('instance is dead!');
          delete MetaMarkers[uid][instance.root.instance];
          continue;
        }
        //console.log(instanceEnv);
        const copy = {...instance};
  
        //merge the scope
        copy.scope = {...copy.scope, ...env.scope};
  
        //if sleeping?
        if (copy.wake) copy.wake();

        const result = await interpretate(expr, copy);
        results.push(result);
      }
    }  
  
    return results;    
}

//DEPRICATED!!!//DEPRICATED!!!
//DEPRICATED!!!//DEPRICATED!!!

const contrainersBox = {};

core.DeleteExecutablesBox = async (args, env) => {
  let containersBoxIDs =  await interpretate(args[0], env);
  if (!containersBoxIDs.length) containersBoxIDs = [containersBoxIDs];

  containersBoxIDs.forEach((e) => {
    console.log("disposing object...");
    e.dispose();
  })
  //somehow remove them
}

//DEPRICATED!!!//DEPRICATED!!!
//DEPRICATED!!!//DEPRICATED!!!

//a much more complicated version, where you are using object to return
core.MarkerContainerExtended = async (args, env) => {
  if (args.length < 3) {
    console.log('MarkerContainerExtended cannot be evaluated on the frontend with only 2 argument!');
    throw 'MarkerContainerExtended cannot be evaluated on the frontend with only 2 argument!';
  }

  const expr = args[0];

  //where this thing will be placed
  //to omitt communication between WLJS and WL
  const containersBoxID =  await interpretate(args[2], env);

  const Box = [];

  //CORRENTLY SUPPORTS ONLY METAMARKER OBJECTS
  const marker = await interpretate(args[1], {...env, hold:true});

  if (marker[0] !== 'MetaMarker') {
    throw 'FrontSubmit cannot be evaluated on the frontend with only MetaMarker as a second argument';
  }

  const uid = await interpretate(marker[1], env);
  const results = [];

  if (uid in MetaMarkers) {
    console.log('found one! ');
    const arr =  Object.values(MetaMarkers[uid]);
    
    for (const instance of arr) {
      //execute inside the container
      console.log('try!');
      //console.log(instanceEnv);
      const copy = {...instance};

      //merge the scope
      copy.scope = {...copy.scope, ...env.scope};
      if (!copy.global.hooks) copy.global.hooks = [];
      copy.global.hooks.push((obj)=>{
        Box.push(obj);
      });

      const result = await interpretate(expr, copy);

      results.push(result);
    }
  }  

  contrainersBox[containersBoxID] = Box;
  return results;
}
