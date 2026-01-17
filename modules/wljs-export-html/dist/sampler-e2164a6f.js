import { A as AnalyzerNode, e as eventNameToString, K as KernelMesh } from './analyzer-4aa51cef.js';

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

function removeDuplicates(arr) {
  // Use a Set to automatically handle uniqueness
  const uniqueElements = new Set(arr);
  // Convert the Set back to an array
  return Array.from(uniqueElements);
}

function countDuplicates(arr) {
  const countMap = new Map();

  for (let i = 0; i < arr.length; i++) {
    const elem = arr[i];
    if (countMap.has(elem)) {
      countMap.set(elem, countMap.get(elem) + 1);
    } else {
      countMap.set(elem, 1);
    }
  }


  return Array.from(countMap.values()).sort((el1, el2)=>(-el1 + el2));
}

let mem = () => 0;

if (performance.memory)
  mem = () => performance.memory.totalJSHeapSize/1024.0;

class SamplerNode {
  que = {}
  aborted = false

  channel = ''
  emitter = () => {}

  recieve = ({name, data}) => {
    if (name in this.que) {
      this.que[name].resolve({name: name, data: data});
      delete this.que[name];
    } else {
      console.warn('Unknown symbol update!');
      console.warn({name, data});
    }
  };

  constructor(instance, channel) {
    this.channel = channel;
    this.instance = instance;

    const node = new AnalyzerNode(this.instance.dump);
    node.analyze();
    this.groups = node.makeGroups(true);

    server.emitt(this.channel, `<|"Info" -> "Ready", "Size" -> 0|>`, 'Progress'); 

    this.groups = this.groups.map((g) => {
      return {...g, eventObjects: this.process(g)};
    });

    console.log(this.animationDump);
    this.groups.map((g) => this.checkAnimations(g, this.instance.dump));

    //purge extra material
    this.groups.forEach((g) => delete g.structure);
    delete this.instance;

    console.log(this.groups);

    return this;
  }

  process(group) {
    const log = this.instance.dump;
    const eventObjects = {};
    
    Object.keys(group.eventObjects).forEach((ev) => {
      eventObjects[ev] = {
        connections: group.connections[ev],
        ...group.eventObjects[ev],
        data: log.filter((o) => {
          if (o.uid) {
            if (eventNameToString(o) == ev) return true;
          }
          
          return false
        }).map((o) => o.data)
      };
      
      const dups = countDuplicates(eventObjects[ev].data);
      console.error(dups);

      if (dups[0] > 30 && dups.length < 3) { //if 30 same events were generated
        eventObjects[ev].animation = true;
      }
      
        
    });

    return eventObjects;
  }

  checkAnimations(group, log) {
    Object.keys(group.eventObjects).forEach((code) => {
      const eventObject = group.eventObjects[code];

      if (!eventObject.animation) return;
      console.warn('Animation detected!');

      const frames = group.structure.filter((e) => (e.type === code)).map((frame) => {
        const elements = frame.elements;
        return elements.map((u) => {
          const i = log[u.pos];
          return i;
        });
      });

      eventObject.animation = frames;

      server.emitt(this.channel, `"Animation ${frames.length} frames detected"`, 'Message'); 

      //server.emitt(this.channel, `<|"Bar" -> ${Math.round(0.0)}, "Max" -> 1.0, "Info" -> ${}, "Size" -> ${}|>`, 'Progress'); 

       
    });

  }

  stop() {
    this.aborted = true;
  }

  async start() {
    for (let group of this.groups) {
      console.log('Sampling... group');
      await this.sample(group);
    }

    const totalSize = this.groups.reduce((acc, curr) => acc + (curr.mesh.length *2), 0);
    console.warn('Finished!');
    server.emitt(this.channel, `<|"Info" -> "Finished!", "Size" -> ${totalSize / 1024}, "Max" -> 1.0, "Bar" -> 1.0|>`, 'Progress'); 
    server.emitt(this.channel, 'True', 'Done'); 
    console.warn(this.groups);
  }

  pump() {
    server.emitt(this.channel, `<|"Info" -> "Compressing data", "Max" -> 1.0, "Bar" -> 0.3|>`, 'Progress'); 
    return this.groups.map((g) => g.mesh);
  }


  async sample(group) {
    let totalPoints = 0;
    let individualPoints = [];
    const map = new Map();

    mem();

    let list = Object.values(group.eventObjects).filter((o) => (!o.animation));

    //if (list.length == 0) return;

    //remove duplicates
    list.forEach((ev) => {
      ev.data = removeDuplicates(ev.data);
    });

    list.forEach((e) => {
      if (totalPoints < 1) totalPoints = e.data.length; else totalPoints *= e.data.length;
      individualPoints.push(e.data.length);
    });

    
    

    if (list.length > 1) {

      console.warn('Mutlip');
      if (this.aborted) return;
      console.warn('Go reqursively!');
      console.warn('Reset to initial state!');
      //let state = new KernelState();

      //reset
      let state;

      for (const ev of list) {
        await this._singleStep(ev, ev.data[0]);
        state = new KernelState(state, {uid: ev.uid, pattern: ev.pattern, data: ev.data[0]});
        if (this.aborted) return;
      }

      map.set('$initialization', list.map((ev) => {
        return {uid: ev.uid, pattern: ev.pattern, data: ev.data[0]}
      }));

      

      if (this.aborted) return;

      const requr = async (depth = 0, state, progress) => {
        if (depth >= list.length) return;

        const event = list[depth];
        for (const d of event.data) {
          state = new KernelState(state, {uid: event.uid, pattern: event.pattern, data: d});
          const symbolData = await this._singleStep(event, d);
          progress();

          symbolData.forEach((s) => {
            state.set(s, map, {noduplicates: true});
          });

          if (this.aborted) return;
          await requr(depth + 1, state, progress);
        }
      };

      let progress = 0;
      let max = totalPoints + individualPoints.reduce((acc, current) => acc + current);

      await requr(0, state, () => {
        progress = progress + 1;
        if (this.aborted) return;
        server.emitt(this.channel, `<|"Info" -> "Sampling recursively ${max} points", "Max" -> ${max}, "Bar" -> ${progress}|>`, 'Progress');
      });

      if (this.aborted) return;

      
    } else {
      //singles considering undefined initial state
    //reset all to possible initial state
      console.warn('SINGLE');
      server.emitt(this.channel, `<|"Info" -> "Sampling ${totalPoints} points", "Max" -> ${totalPoints}, "Bar" -> 0.0|>`, 'Progress'); 
      console.warn(list);

    for (const event of list) {
      console.warn('Reset to initial state!');
      //let state = new KernelState();

      if (this.aborted) return;

      //reset
      let state;

      for (const ev of list) {
        await this._singleStep(ev, ev.data[0]);
        state = new KernelState(state, {uid: ev.uid, pattern: ev.pattern, data: ev.data[0]});
        if (this.aborted) return;
      }

      console.warn('reseted succesfully');
      console.warn('starting sampling process');

      

      

      let index = 0;
      for (const d of event.data) {
        index += 1;
        if (this.aborted) return;
        server.emitt(this.channel, `<|"Info" -> "Sampling ${event.data.length} points", "Max" -> ${event.data.length}, "Bar" -> ${index}|>`, 'Progress');
        state = new KernelState(state, {uid: event.uid, pattern: event.pattern, data: d});
        const symbolData = await this._singleStep(event, d);
        symbolData.forEach((s) => {
          state.set(s, map);
        });
      }

      if (this.aborted) return;
      
    }    }

    console.warn('Checking animations');
    if (this.aborted) return;

    list = Object.values(group.eventObjects).filter((o) => (o.animation));
    if (list.length) {
      console.warn(list);
      
      console.log('Feed directly');

      for (const event of list) {
        let state = undefined;
        let index = 0;
        server.emitt(this.channel, `<|"Info" -> "Sampling ${event.animation.length} frames", "Max" -> ${event.animation.length}, "Bar" -> ${0}|>`, 'Progress');

        for (const frame of event.animation) {
          index += 1;
          server.emitt(this.channel, `<|"Max" -> ${event.animation.length}, "Bar" -> ${index}|>`, 'Progress');

          state = new KernelState(state, {uid: event.uid, pattern: event.pattern, data: event.data[0]});
          frame.forEach((s) => {
            state.set(s, map);
          });
        }
      }
    }

    group.mesh = (new KernelMesh(group, map)).serialize();
    
    return group;
  }

  dispose() {
    server.emitt(this.channel, `<|"Max" -> 1.0, "Bar" -> 1.0|>`, 'Progress'); 
    delete this.groups;
  }



  _singleStep(e, data) {
    const promises = e.connections.map((sym) => {
      const def = new Deferred();
      this.que[sym] = def;
      return def.promise;
    });

    const p = new Deferred();

    Promise.all(promises).then((symbolData) => {
      p.resolve(symbolData);
    });

    this.emitter({uid: e.uid, data: data, pattern: e.pattern});

    return p.promise;
  }

}

export { SamplerNode };
