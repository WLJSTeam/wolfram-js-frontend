import { Balanced } from "node-balanced"

export const ListMatch = (cursor) => {
const m = new Balanced({
    //head: /F\[/,
    open: "{",
    close: "}",
    balance: false
  })
  .matchContentsInBetweenBrackets(cursor, [])[0];
  
    const sub = cursor.substring(
      m.index + m.head.length,
      m.index + m.length - 1
    );


    //console.log(sub);

    const compoundMatches = new Balanced({
      open: ["[", "{"],
      close: ["]", "}"],
      balance: [false, false]
    }).matchContentsInBetweenBrackets(sub, []);

    let SyntaxTree = [];

    let lastIndex = 0;
    //console.log(compoundMatches);

    compoundMatches.forEach((e) => {
      SyntaxTree.push({
        begin: sub.substring(lastIndex, e.index),
        expr: sub.substring(e.index, e.index + e.length),
        type: 0
      });
      lastIndex = e.index + e.length;
    });

    if (lastIndex < sub.length - 1) {
      SyntaxTree.push({
        begin: sub.substring(lastIndex),
        type: 1
      });
    }

    let args = [];
    
    //console.log(SyntaxTree);

    SyntaxTree.reverse().forEach((s) => {
      
      const localargs = [];
      
      if (s.begin.length == 0) {
        //console.log(s);
        localargs.push(s.expr);
        
        
      } else {

      let matches = s.begin.split(",");
      //console.log(matches);
      if (SyntaxTree.length > 1) matches.shift();
      if (matches.length == 0) matches = [s.begin];

      if (s.type == 0) {
        localargs.push((matches.pop() + s.expr).trim());
        if (matches.length > 0)
          matches.forEach((a) => {
            localargs.push(a.trim());
          });
      } else {
        matches.forEach((a) => {
          localargs.push(a.trim());
        });
      }
      }

      args.push(...localargs.reverse());
    });
    
    return args.reverse()
}