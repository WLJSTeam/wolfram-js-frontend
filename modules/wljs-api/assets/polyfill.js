

//setting up global virtual server
const server = {};
window.server = server;


//polyfill for WLJSIO package
server.kernel = {
  io: {
    fetch: async (symbol, args = []) => {
      console.warn('kernel symbol request');
      let uid = await fetch(addr + '/api/kernels/fetch/', { 
        method: 'POST', 
        body:JSON.stringify({
          'Symbol': symbol,
          'Args': args,
          'Kernel': null
        }),
        ...fetchOptions 
      });

      uid = await uid.json();

      console.warn('Request id: ', uid);

      let resolvedQ = false;
      let data;

      while(!resolvedQ) {

        await delay(polingDelay);
        console.log('checking...');
        data = await fetch(addr + '/api/kernels/fetch/get/', { 
          method: 'POST', 
          body:JSON.stringify({
            'UId': uid
          }),
          ...fetchOptions 
        }); 
        data = await data.json();
      
        resolvedQ = data.ReadyQ;

      }

      console.warn(data.Result);

      return data.Result;

    },
    fire: () => {
      console.warn('server.kernel.io.fire is not supported')
    },
    poke: () => {
      console.warn('server.kernel.io.poke is not supported')
    }
  },

  emitt: () => {
    console.warn('server.kernel.emitt is not supported')
  },

  ask: () => {
    console.warn('server.kernel.ask is not supported')
  }
};

var addr = 'http://127.0.0.1:20560';
var fetchOptions = {};
var polingDelay = 300;

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

server.configure = ({address = 'http://127.0.0.1:20560', fetchOptions = {}, polingDelay = 300}) => {
    addr = address;
    fetchOptions = fetchOptions;
    polingDelay = polingDelay;
}

server.waitForConnection = async () => {
    try {
      const res = await fetch(addr + '/api/ready/', { method: 'POST', ...fetchOptions });
      console.warn(res);
      const r = await res.json();
      if (!r.ReadyQ) {
        await delay(polingDelay);
        await checkConnection();
      }
    } catch (err) {
      await delay(polingDelay);
      await checkConnection();
    }
  };

server.findKernel = async () => {
    const res = await fetch(addr + '/api/kernels/list/', {
        method:'POST', ...fetchOptions
    });
    
    const body = await res.json();


    const valid = body.filter((el) => el.ContainerReadyQ);
    if (valid.length == 0) {
        await delay(polingDelay);
        return await findKernel();
    }

    return valid[0].Hash;
}

server.getResult = async (kernel, transaction) => {
    await delay(polingDelay);

    let result = await fetch(addr + '/api/transactions/get/', {
        method:'POST',
        body:JSON.stringify({
            'Hash': transaction
        }),
        ...fetchOptions
    });

    
    result = await result.json();
    console.log(result);
    

    if (!(result.State == 'Idle')) {
      return await server.getResult(kernel, transaction);
    }
    
    return result.Result;

}

server.createTransaction = async (kernel, data) => {
    const trimmed = data.trim();
    if (trimmed.length == 0) return;

    let transaction = await fetch(addr + '/api/transactions/create/', {
                    method:'POST',
                    body:JSON.stringify({
                        'Kernel': kernel,
                        'Data': trimmed
                    }),
                    ...fetchOptions
    });

    transaction = await transaction.json();
    return transaction;
}

server.abortKernel = async (kernel) => {
  let res = await fetch(addr + '/api/kernels/abort/', {
                  method:'POST',
                  body:JSON.stringify({
                      'Hash': kernel
                  }),
                  ...fetchOptions
  });

  res = await res.json();
  return res;
}

server.requestCDNExtensionsList = async () => {
    const listRes = await fetch(addr + '/api/cdn/list/', { method: 'POST', ...fetchOptions });
    return await listRes.json();
}

server.requestCDNJavascript = async (list) => {
    const listRes = await fetch(addr + '/api/cdn/get/js/', { method: 'POST', body:JSON.stringify(list), ...fetchOptions });
    return await listRes.json();
}

server.requestCDNStyles = async () => {
    const listRes = await fetch(addr + '/api/cdn/get/styles/', { method: 'POST', ...fetchOptions });
    return await listRes.json();
}

server.requestObject = async (kernel, uid) => {
    console.log('request an object: ', uid);
    let r = await fetch(addr + '/api/frontendobjects/get/', {
        method:'POST',
        body:JSON.stringify({
          'UId': uid,
          'Kernel': kernel
        }),
        ...fetchOptions
    });


    r = await r.json();

    console.log(r);

    if (r.Resolved == true) {
        return JSON.parse(r.Data);
    }

    console.log('waiting...');

    await delay(polingDelay);

    return await server.requestObject(kernel, uid)
}

server.cachingFunction = async (objectId) => {
    const res = await server.requestObject(null, objectId);
    return res;
}

//implemetation of get method depends on execution env
if (!window.ObjectStorage) {
    window.ObjectStorage = class {

    };

    console.error('window.ObjectStorage is absent. Most likely you did not include global core scripts as modules.');
}

window.ObjectStorage.prototype.get = function () {
      if (this.cached) return this.cache;
      const self = this;
      const promise = new Deferred();

      server.cachingFunction(self.uid).then((result) => {
        if (!result || result == '$Failed') {
            console.warn('Rejected! Not found: ', self.uid);
            console.warn(result);
            promise.reject();
            return;
        }
        self.cache = result;
        promise.resolve(self.cache);
      })
  
      return promise.promise;
    }

if (!window.core) {
    window.core = {};
    console.error('window.core is absent. Most likely you did not include global core scripts as modules.');
}    


//Polyfills fro WLJSIO package
core.Offload = (args, env) => {
    if (args.length > 1) {
        //alternative path - checking options
        //do it in ugly superfast way
        if (args[1][1] === "'Static'") {
            if (args[1][2]) {
                return interpretate(args[0], {...env, static: true});
            }
        } else if (args.length > 2) {
            if (args[2][1] === "'Static'") {
                if (args[2][2]) {
                    return interpretate(args[0], {...env, static: true});
                }                
            }
        }
    }
  
    return interpretate(args[0], env);
  }

  core.Medium = () => 0.7
  
  core.Offload.update = (args, env) => {
    if (args.length > 1) {
        //alternative path - checking options
        //do it in ugly superfast way
  
        //Volitile -> False -> Reject updates
  
        //low-level optimizations, we dont' need to spend time on parsing options
        if (args[1][1] === "'Volatile'") {
            if (!args[1][2]) {
                console.log('Update was rejected (Nonvolatile)');
                return;
            }
        } else if (args.length > 2) {
            if (args[2][1] === "'Volatile'") {
                if (!args[2][2]) {
                    console.log('Update was rejected (Nonvolatile)');
                    return;
                }                
            }
        }
    }
  
    return interpretate(args[0], env);
  }

