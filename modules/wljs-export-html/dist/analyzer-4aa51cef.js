function filterKeys(object, filterFunction) {
    // Create a new object to store the filtered key-value pairs
    const filteredObject = {};
  
    // Iterate over each key in the input object
    for (const key in object) {
      // Check if the property is a direct property of the object
      if (object.hasOwnProperty(key)) {
        // Apply the filter function to the key
        if (filterFunction(key)) {
          // If the filter function returns true, add the key-value pair to the filtered object
          filteredObject[key] = object[key];
        }
      }
    }
  
    // Return the filtered object
    return filteredObject;
  }
  
  function analyzeTimeSeries(data) {
      const letterNumberMap = {};
      const letterCount = {};
      const totalConnections = {};
  
      let i = 0;
      while (i < data.length) {
          const char = data[i];
          if (isNaN(char)) {
              // It's a letter
              if (!letterCount[char]) {
                  letterCount[char] = 0;
              }
              letterCount[char]++;
              
              // Check following characters for numbers
              i++;
              while (i < data.length && !isNaN(data[i])) {
                  const num = data[i];
                  if (!letterNumberMap[char]) {
                      letterNumberMap[char] = {};
                  }
                  if (!letterNumberMap[char][num]) {
                      letterNumberMap[char][num] = 0;
                  }
                  letterNumberMap[char][num]++;
                  if (!totalConnections[char]) {
                      totalConnections[char] = 0;
                  }
                  totalConnections[char]++;
                  i++;
              }
          } else {
              i++;
          }
      }
  
      // Calculate probabilities
      const probabilities = {};
      for (let letter in letterNumberMap) {
          probabilities[letter] = {};
          for (let number in letterNumberMap[letter]) {
              probabilities[letter][number] = letterNumberMap[letter][number] / totalConnections[letter];
          }
        const max = Math.max(...Object.values(probabilities[letter]));
        Object.keys(probabilities[letter]).map((n) => probabilities[letter][n]=probabilities[letter][n]/max );
      }
  
      return { letterNumberMap, probabilities, letterCount };
  }
  function findCorrespondences(timeSeries, connections) {
      const correspondences = [];
      const pending = [];

      console.log(timeSeries);
      console.log(connections);

      let i = 0;
  
      while (i < timeSeries.length) {
          const char = timeSeries[i];
          if (isNaN(char) && !connections[char]) {
            i++;
            continue;
          }
        
          if (isNaN(char)) {
            pending.push({type: char, elements: [], pos: i});
          } else {
            if (pending.length < 1) {
              i++;
              continue;
            }

            pending[0].elements.push({data: char, pos: i});
            if (pending[0].elements.length == connections[pending[0].type].length) {
              correspondences.push(pending.shift());
            }
          }
          i++;
      }
  
      return correspondences;
  }
  
  function findPositions(timeSeries) {
  // Example usage
  const result = analyzeTimeSeries(timeSeries);
  
  console.log("Connections:", result.letterNumberMap);
  console.log("Probabilities:", result.probabilities);
  console.log("Letter Counts:", result.letterCount);
  
  let connected = {};
  Object.keys(result.letterNumberMap).forEach((letter) => {
    connected[letter] = [];
    Object.keys(result.probabilities[letter]).forEach((num) => {
      if (result.probabilities[letter][num] >= 0.5) connected[letter].push(String(num));
    });
  });
    
    const structure = findCorrespondences(timeSeries, connected);
    
    console.warn(connected);
    const connectionGroups = splitIntoNonOverlappingGroups(connected);
    console.warn(connectionGroups);
    console.warn('fuck');
    
    const groups = [];
    connectionGroups.forEach((group) => {
      groups.push({structure: structure.filter((e) => (e.type in group)), count:filterKeys(result.letterCount, (e) => (e in group)), probabilities: filterKeys(result.probabilities, (e) => (e in group)),  connections: group});
    });
  
    
    return groups;
  
  
  //return {structure: findCorrespondences(timeSeries, connected), connections: connected}
  }
  function splitIntoNonOverlappingGroups(obj) {
      // Function to check if two arrays intersect
      function arraysIntersect(arr1, arr2) {
          return arr1.some(item => arr2.includes(item));
      }
  
      // Initialize an array to hold the result groups
      let result = [];
  
      // Iterate over each key-value pair in the object
      for (let key in obj) {
          let newGroup = {};
          newGroup[key] = obj[key];
  
          // Track which groups intersect with the current key-value pair
          let intersectingGroups = [];
  
          for (let group of result) {
              let groupKeys = Object.keys(group);
              let groupValues = groupKeys.reduce((acc, k) => acc.concat(group[k]), []);
  
              // Check if there's an intersection with the current group
              if (arraysIntersect(groupValues, obj[key])) {
                  intersectingGroups.push(group);
              }
          }
  
          // Merge intersecting groups and add the new key-value pair
          if (intersectingGroups.length > 0) {
              // Create a combined group
              let combinedGroup = intersectingGroups.reduce((acc, group) => {
                  return Object.assign(acc, group);
              }, newGroup);
  
              // Remove the old intersecting groups
              result = result.filter(group => !intersectingGroups.includes(group));
  
              // Add the combined group to the result
              result.push(combinedGroup);
          } else {
              // If no intersecting group found, add the new group to the result
              result.push(newGroup);
          }
      }
  
      return result;
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

const letters = 'ABCDEFGHIJKLMNOP';
const numbers = '123456789';

class AnalyzerNode {
    tokens = {
        series:[],
        letters:{},
        fromLetters: {},
        fromDigits: {},
        numbers:{},
        eventObjects:{}
    }

    log = []

    constructor(log) {
        this.log = log;
        const tokens = this.tokens;

        this.log.forEach((el) => {
            if (el.uid) {
                tokens.series.push([0, eventNameToString(el)]);
                tokens.eventObjects[eventNameToString(el)] = {uid: el.uid, pattern: el.pattern};
            } else {
                tokens.series.push([1, String(el.name)]);
            }
          });
          
          tokens.series.forEach((t) => {
            if (t[0] > 0) {
              tokens.numbers[t[1]] = true;
            } else {
              tokens.letters[t[1]] = true;
            }
          });
          
          Object.keys(tokens.letters).forEach((t, i) => {
            tokens.letters[t] = letters.charAt(i);
            tokens.fromLetters[letters.charAt(i)] = t;
          });
          
          Object.keys(tokens.numbers).forEach((t, i) => {
            tokens.numbers[t] = numbers.charAt(i);
            tokens.fromDigits[numbers.charAt(i)] = t;
          });
          
          
          tokens.series = tokens.series.map((el) => {
            if (el[0] > 0) {
              return tokens.numbers[el[1]]
            } else {
              return tokens.letters[el[1]]
            }
          }).join('');

        return this;
    }

    analyze() {
        let groups = findPositions(this.tokens.series);
  
        groups = groups.map((g) => {
          g.database = new Map();
          g.whitelist = Object.keys(g.connections).map((e) => this.tokens.fromLetters[e]);
          return g;
        });

        this.groups = groups;
        return groups;
    }

    makeGroups(fullFormQ) {
        if (fullFormQ) {
            return this.groups.map((group) => {
              const tranformed = {
                  count: {},
                  probabilities: {},
                  connections: {},
                  structure: []
              };

              Object.keys(group.count).forEach((k) => {
                  tranformed.count[this.tokens.fromLetters[k]] =     group.count[k];    
              });

              Object.keys(group.probabilities).forEach((k) => {
                  tranformed.probabilities[this.tokens.fromLetters[k]] = {};
                  Object.keys(group.probabilities[k]).forEach((kk) => {
                      tranformed.probabilities[this.tokens.fromLetters[k]][this.tokens.fromDigits[kk]] = group.probabilities[k][kk];
                  });
              });

              Object.keys(group.connections).forEach((k) => {
                  tranformed.connections[this.tokens.fromLetters[k]] = group.connections[k].map((el) => this.tokens.fromDigits[el]);
              });

           

              tranformed.structure = group.structure.map((element) => {
                const type = this.tokens.fromLetters[element.type];
                return {
                  ...element,
                  type: type,
                  elements : element.elements.map((el) => {
                    return {
                      ...el,
                      data: this.tokens.fromDigits[el.data]
                    }
                  })
                };
              });

              tranformed.eventObjects = filterKeys(this.tokens.eventObjects, (e) => (e in tranformed.connections));

              return tranformed;

          });
        }

        return this.groups.map((group) => {
            const tranformed = {
                count: {},
                probabilities: {},
                connections: {}
            };

            Object.keys(group.count).forEach((k) => {
                tranformed.count[this.tokens.fromLetters[k]] =     group.count[k];    
            });

            Object.keys(group.probabilities).forEach((k) => {
                tranformed.probabilities[this.tokens.fromLetters[k]] = {};
                Object.keys(group.probabilities[k]).forEach((kk) => {
                    tranformed.probabilities[this.tokens.fromLetters[k]][this.tokens.fromDigits[kk]] = group.probabilities[k][kk];
                });
            });

            Object.keys(group.connections).forEach((k) => {
                tranformed.connections[this.tokens.fromLetters[k]] = group.connections[k].map((el) => this.tokens.fromDigits[el]);
            });




            
            tranformed.eventObjects = filterKeys(this.tokens.eventObjects, (e) => (e in tranformed.connections));
            
            return tranformed;

        });
    }


}

var analyzer = /*#__PURE__*/Object.freeze({
  __proto__: null,
  AnalyzerNode: AnalyzerNode
});

export { AnalyzerNode as A, KernelMesh as K, analyzer as a, eventNameToString as e };
