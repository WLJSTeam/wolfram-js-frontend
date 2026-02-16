import { explodeArgs } from 'priceless-mathematica/src/sugar/matcher'

import { Balanced, getRangesForMatch, rangesWithout } from "node-balanced";

String.prototype.splitNoQuotes = function (expr) {
 
const arr = [];
const source = this;

var ignore = getRangesForMatch(source, /\"[^\"]*\"/g);
var quotes = getRangesForMatch(source, new RegExp(expr, 'g'));
quotes = rangesWithout(quotes, ignore); 

let index = 0;
for (let i=0; i<quotes.length; ++i) {
  arr.push(source.substring(index, quotes[i].index));
  index = quotes[i].index + 1;
}

if (index < source.length) {
  arr.push(source.substring(index));
}

return arr;
}

const explodeArgs2 = (re, cursor, pos, f) => {
    new Balanced({
        head: re,
        open: "[",
        close: "]",
        balance: false
    })
        .matchContentsInBetweenBrackets(cursor.value, [])
        .forEach(function (m) {
        var sub = cursor.value.substring(m.index + m.head.length, m.index + m.length - 1);
        
      
        const blockString = getRangesForMatch(sub, /\"[^\"]*\"/g);
      
        var compoundMatches = new Balanced({
            open: ["[", "{"],
            close: ["]", "}"],
            balance: [false, false],
            ignore: Array.prototype.concat.call([], blockString)
        }).matchContentsInBetweenBrackets(sub, []);
      
        let SyntaxTree = [];
        var lastIndex = 0;
        //console.log(compoundMatches);
      
       
      
        const getNext = (list) => {
          if (list.length == 0) {
            if (lastIndex < sub.length) {
              const before = sub.substring(lastIndex).trim();
              if (before[0] === ',') {
                SyntaxTree.push({before: before, type: 1});
              } else {
                const splitted = before.splitNoQuotes(',');
                if (splitted.length == 1) {
                  let prev = SyntaxTree[SyntaxTree.length-1];
                  console.log(SyntaxTree.length);
                  //prev.enclosed += before;
                  SyntaxTree[SyntaxTree.length-1] = prev;
                } else {
                  let prev = SyntaxTree[SyntaxTree.length-1];
                  prev.enclosed += splitted.shift();
                  SyntaxTree[SyntaxTree.length-1] = prev;  
                  
                  SyntaxTree.push({before: ','+splitted.join(','), type: 1});
                }
              }
            }
            return;
          }
          
          const e = list.shift();
          const before = sub.substring(lastIndex, e.index).trim();
          const enclosed = sub.substring(e.index, e.index + e.length).trim();
        
          
          
          if (lastIndex > 0) {
            if (before[0] === ',') {
              SyntaxTree.push({before, enclosed, type: 0});
            } else {
              let prev = SyntaxTree[SyntaxTree.length-1];
              prev.enclosed += before + enclosed;
              SyntaxTree[SyntaxTree.length-1] = prev;
            }
          } else {
            SyntaxTree.push({before, enclosed, type: 0});
          }
          
          lastIndex = e.index + e.length;
          getNext(list);
        }

        if (compoundMatches.length !== 0)
          getNext(compoundMatches);
        else
          SyntaxTree.push({before: sub, type: 1});
      
     
        

        var args = [];
      
        SyntaxTree.reverse().forEach(function (s) {
            var localargs = [];
            if (s.before.length == 0) {
                localargs.push(s.enclosed);
                args.push(localargs);
                return;
            }
            var matches = s.before.splitNoQuotes(",");
            if (SyntaxTree.length > 1)
                matches.shift();
          
   
          
            if (matches.length == 0) {
                matches = [s.before];
              
            }
          
            if (s.type == 0) {
                const a = ((matches.pop() + s.enclosed));
                  matches.forEach(function (a) {
                     localargs.push(a.trim());
                });
              localargs.push(a.trim());
              
            } else {
                matches.forEach(function (a) {
                    localargs.push(a.trim());
                });
            }
            args.push(localargs);
        });

        f(pos + m.index, {
            length: m.length,
            pos: pos + m.index,
            args: args.reverse().flat(),
            str: sub
        });

    });
}

explodeArgs2(/CM6Fraction\[/, {value: `CM6Fraction[CM6Fraction[1, _], _]  222 `}, {},  (a, obj) => {
  console.log(obj);
});

explodeArgs(/CM6Fraction\[/, {value: `CM6Fraction[CM6Fraction[1, _], _]  222 `}, {},  (a, obj) => {
  console.log(obj);
});




/*
let then, now;
let temp = [];

temp = [];
then = new Date; //then and now were already declared
for (let i = 0; i < 2000; i++) {
  explodeArgs(/CM6Fraction\[/, {value: '1 - CM6Fraction[Tjj[], 8+ 4 Re[ CM6Sqrt[lor + 3] ], 77, 88, CM6Superscript[ Im[ CM6Sqrt[lor + 3] ], 2] + CM6Superscript[(1 + Re[ CM6Sqrt[lor + 3] ]), 2] + {F[1] + CM6[1,2]}, 33, G[33] + 7, "5, 6", g]'}, {},  (a, obj) => {
  temp.push(obj);
});
}
now = new Date;
now - then

temp = [];
then = new Date; //then and now were already declared
for (let i = 0; i < 2000; i++) {
  explodeArgs2(/CM6Fraction\[/, {value: '1 - CM6Fraction[Tjj[], 8+ 4 Re[ CM6Sqrt[lor + 3] ], 77, 88, CM6Superscript[ Im[ CM6Sqrt[lor + 3] ], 2] + CM6Superscript[(1 + Re[ CM6Sqrt[lor + 3] ]), 2] + {F[1] + CM6[1,2]}, 33, G[33] + 7, "5, 6", g]'}, {},  (a, obj) => {
  temp.push(obj);
});
}
now = new Date;
now - then*/
