const permutator = (inputArr) => {
  let result = [];

  const permute = (arr, m = []) => {
    if (arr.length === 0) {
      result.push(m);
    } else {
      for (let i = 0; i < arr.length; i++) {
        let curr = arr.slice();
        let next = curr.splice(i, 1);
        permute(curr.slice(), m.concat(next));
     }
   }
 };

 permute(inputArr);

 return result;
};

class KernelState {
  state = {}
  hash = ''
  
  constructor (state = undefined, ev, ffast = false) {
    if (state) this.state = {...state.state};
    const code = String(ev.uid) + String(ev.pattern);
    this.state[code] = ev.data;
    const self = this;
    if (ffast) {
      this.hash = [Object.keys(this.state)].map((variant) => variant.reduce((acc, e) => {
        const h = 'dt'+String(self.state[e]) + 'st'+String(e);
        return acc + h;
      }, 0));

      return this;
    }

    this.hash = permutator(Object.keys(this.state)).map((variant) => variant.reduce((acc, e) => {
      const h = 'dt'+String(self.state[e]) + 'st'+String(e);
      return acc + h;
    }, 0));


    return this;
  }

  match(state) {
    for (const prop of Object.keys(this.state)) {
      if (state[prop] != this.state[prop]) return false;
    }

    return true;
  }
  
  set (o, m, opts = {}) {
    let found = false;

    for (const h of this.hash) {
      if (m.has(h)) {
        found = h;
        break;
      }
      
    }

    let object;

    if (!found) {
      object = {$state: this.state};
      found = this.hash[0];
      m.set(found, object);
      for (let k = 1; k<this.hash.length; ++k) {
        if (m.has(this.hash[k])) {
          console.error('COLLISION!');
          console.warn(m.get(this.state));
          const fwd = m.get(this.hash[k]);
          console.warn(fwd);
          if (!fwd.$collided) fwd.$collided = [];
          const extra = {};
          fwd.$collided.push(extra);
          extra.$state = this.state;
          extra.fwd = found;
          continue;
        }
        m.set(this.hash[k], {fwd: found, $state: this.state});
      }
    } else {
      object = m.get(found);
      if (!this.match(object.$state)) {
        console.warn('Collision!');
        if (!object.$collided) object.$collided = [];
        const extra = {};
        object.$collided.push(extra);
        extra.$state = this.state;
        object = extra;
      }
    }
    

    //object.state = {...this.state};//debug only
    if (opts.noduplicates) {
      object[o.name] = {set:[o.data], i:0};
      return this;
    }

    if (o.name in object) {
      object[o.name].set.push(o.data);
    } else {
      object[o.name] = {i:0, set:[o.data]}; 
    }
  }
  
  exec (m, fn) {
    let h = this.hash[0];
    while(m.has(h)) {
      let o = m.get(h);

      if (!this.match(o.$state)) {
        console.warn('COLLISION!');
        console.warn(o);
        console.warn(this);
        o = object.$collided.find((el) => this.match(el.$state));
      }

      if (o.fwd) {
        h = o.fwd;
        continue;
      }

      //console.warn(this.state);
      //console.warn(o);

      return fn(o)
    }

    console.error('State does not exists!');
    console.log(this.state);
    console.log(this.hash);
  }
}

const eventNameToString = (ev) => (String(ev.uid) + String(ev.pattern));

class KernelMesh {
    constructor(group, database) {
      this.database = database;
      this.whitelist = Object.keys(group.eventObjects);
      return this;
    }
    
    test(msg) {
  
      return this.whitelist.includes(eventNameToString(msg));
    }
    
    serialize() {
      return JSON.stringify({db:Object.fromEntries(this.database), wl:this.whitelist});
    }
    
    static unpack(string) {
      const data = JSON.parse(  string );
      const wlKeys = {};
      data.wl.forEach((k) => wlKeys[k] = true);

      const o = new KernelMesh({eventObjects: wlKeys}, new Map(Object.entries(data.db)));
      return o;
    }
}

window.KernelState = KernelState;
window.KernelMesh = KernelMesh;
