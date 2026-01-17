import { RangeSetBuilder } from "@codemirror/state";
import { Balanced, getRangesForMatch, rangesWithout, isIndexInRage } from "node-balanced";

const matchHeadExcluding = (regexp, string, ignoreRanges) => {
	var pattern = new RegExp(regexp),
		match,
		matches = [];

	if (string) {
		while ((match = pattern.exec(string))) {
			
      if (ignoreRanges) {
				var ignore = false;
				
				for (var i = 0; i < ignoreRanges.length; i++) {
					if (isIndexInRage(match.index, ignoreRanges[i])) {
						ignore = true;
						continue;
					}
				}

				if (ignore) {
					continue;
				}
			}      
      
			matches.push({index: match.index, length: match[0].length, match: match[0]});
			
			if (!match[0].length) {
				pattern.lastIndex++;
			}
		}
	}

	return matches;
}

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

export const matchArguments = (target, separator) => {
    const ignoreInner = new Balanced({
        open: /\(\*\w+\[\*\)/,
        close: /\(\*\]\w+\*\)/
      }).matchContentsInBetweenBrackets(target, []);

      //console.log(ignoreInner);
      
      const separators = matchHeadExcluding(separator, target, ignoreInner);

      //console.log(separators);
      //console.log(target);
      /*if (separators.length == 0) return ({
        index: m.index,
        content: target
      });*/

      const args = [];

      let index = 0;
      let stop = target.length; 
      let prev;
      let s;
      
      while (s = separators.shift()) {
        if (prev) index = prev.index + prev.length;
        const sliced = target.slice(index, s.index);
        args.push(
        {
          from: index,
          //to: s.index,
          length: sliced.length, 
          body: sliced
        }
          //target.slice(index, s.index)
        );
        //index = s.index;
        prev = s;
      }
      
      let lastIndex = 0;
      if (prev) lastIndex = prev.index + prev.length;        

      if (lastIndex != target.length) {
        const sliced = target.slice(lastIndex);
        args.push(
        {
          from: lastIndex, 
          //to: target.length,
          length: sliced.length,
          body: sliced
        }
        //target.slice(lastIndex)
        )
      };

      return args;
}

export const explodeArgs = (tag, cursor, pos, f) => {

    new Balanced({
        open: "(*"+tag+"[*)",
        close: "(*]"+tag+"*)",
        balance: false
    })
        .matchContentsInBetweenBrackets(cursor.value, [])
        .forEach(function (m) { 
          //console.log(m);
  
          const target = cursor.value.slice(m.index+m.head.length, m.index + m.length - m.tail.length);
          //console.log(target);
  
          //console.log(args);
          //console.log('working');

          f(pos + m.index, {
            length: m.length,
            pos: pos + m.index,
            argsPos: pos + m.index+m.head.length,
            str: target
          });
    });
}

function iterMatches(doc, re, from, to, f) {
    //re.lastIndex = 0;
    var _loop_1 = function (cursor, pos, m) {
        if (!cursor.lineBreak) {

            explodeArgs(re, cursor, pos, f);        
            
        }
    };
    for (var cursor = doc.iterRange(from, to), pos = from, m = void 0; !cursor.next().done; pos += cursor.value.length) {
        _loop_1(cursor, pos, m);
    }
}

function iterMatches2(doc, re, from, to, f, fromLine, toLine) {
    //re.lastIndex = 0;
    var _loop_1 = function (cursor, pos, m) {
        if (!cursor.lineBreak) {

            explodeArgs(re, cursor, pos, f);        
            
        }
    };
    for (var cursor = doc.iterRange(fromLine.from, to), pos = fromLine.from, m = void 0; !cursor.next().done; pos += cursor.value.length) {
        _loop_1(cursor, pos, m);
    }
}


function matchRanges(view, maxLength) {
    var visible = view.visibleRanges;
    if (visible.length == 1 &&
        visible[0].from == view.viewport.from &&
        visible[0].to == view.viewport.to)
        return visible;
    var result = [];
    for (var _i = 0, visible_1 = visible; _i < visible_1.length; _i++) {
        var _a = visible_1[_i], from = _a.from, to = _a.to;
        from = Math.max(view.state.doc.lineAt(from).from, from - maxLength);
        to = Math.min(view.state.doc.lineAt(to).to, to + maxLength);
        if (result.length && result[result.length - 1].to >= from)
            result[result.length - 1].to = to;
        else
            result.push({ from: from, to: to });
    }
    return result;
}
/// Helper class used to make it easier to maintain decorations on
/// visible code that matches a given regular expression. To be used
/// in a [view plugin](#view.ViewPlugin). Instances of this object
/// represent a matching configuration.
var BallancedMatchDecorator2 = /** @class */ (function () {
    /// Create a decorator.
    function BallancedMatchDecorator2(config) {
        var tag = config.tag, decoration = config.decoration, decorate = config.decorate, boundary = config.boundary, _a = config.maxLength, maxLength = _a === void 0 ? 10000000 : _a;
        //if (!tag.global) throw new RangeError("The regular expression given to MatchDecorator should have its 'g' flag set")
        this.tag = tag;
        if (decorate) {
            this.addMatch = function (match, view, from, add) {
                return decorate(add, from, from + match.length, match, view);
            };
        }
        else if (typeof decoration == "function") {
            this.addMatch = function (match, view, from, add) {
                var deco = decoration(match, view, from);
                if (deco)
                    add(from, from + match.length, deco);
            };
        }
        else if (decoration) {
            this.addMatch = function (match, _view, from, add) {
                return add(from, from + match.length, decoration);
            };
        }
        else {
            throw new RangeError("Either 'decorate' or 'decoration' should be provided to MatchDecorator");
        }
        this.boundary = boundary;
        this.maxLength = maxLength;
    }
    /// Compute the full set of decorations for matches in the given
    /// view's viewport. You'll want to call this when initializing your
    /// plugin.
    BallancedMatchDecorator2.prototype.createDeco = function (view) {
        var _this = this;
        var build = new RangeSetBuilder(), add = build.add.bind(build);
        for (var _i = 0, _a = matchRanges(view, this.maxLength); _i < _a.length; _i++) {
            var _b = _a[_i], from = _b.from, to = _b.to;
            /*console.log({
                fromLine: from,
                toLine: to,
                'view.state.doc':view.state.doc, 
                'this_1.tag': this.tag
            });*/

            iterMatches(view.state.doc, this.tag, from, to, function (from, m) {
                return _this.addMatch(m, view, from, add);
            });
        }
        return build.finish();
    };
    /// Update a set of decorations for a view update. `deco` _must_ be
    /// the set of decorations produced by _this_ `MatchDecorator` for
    /// the view state before the update.
    BallancedMatchDecorator2.prototype.updateDeco = function (update, deco) {
        var changeFrom = 1e9, changeTo = -1;
        if (update.docChanged)
            update.changes.iterChanges(function (_f, _t, from, to) {
                if (to > update.view.viewport.from && from < update.view.viewport.to) {
                    changeFrom = Math.min(from, changeFrom);
                    changeTo = Math.max(to, changeTo);
                }
            });
        if (update.viewportChanged || changeTo - changeFrom > 1000) {
            //console.log('createDeco');
            return this.createDeco(update.view);
        }
        if (changeTo > -1) {
            //console.log('updatRanges');
            return this.updateRange(update.view, deco.map(update.changes), changeFrom, changeTo);
        }
        return deco;
    };
    BallancedMatchDecorator2.prototype.updateRange = function (view, deco, updateFrom, updateTo) {
        var _this = this;
        var _loop_2 = function (r) {
            var from = Math.max(r.from, updateFrom), to = Math.min(r.to, updateTo);
            if (to > from) {
                var fromLine = view.state.doc.lineAt(from), toLine = fromLine.to < to ? view.state.doc.lineAt(to) : fromLine;
                var start_1 = Math.max(r.from, fromLine.from), end_1 = Math.min(r.to, toLine.to);
                if (this_1.boundary) {
                    for (; from > fromLine.from; from--)
                        if (this_1.boundary.test(fromLine.text[from - 1 - fromLine.from])) {
                            start_1 = from;
                            break;
                        }
                    for (; to < toLine.to; to++)
                        if (this_1.boundary.test(toLine.text[to - toLine.from])) {
                            end_1 = to;
                            break;
                        }
                }
                var ranges_1 = [], m = void 0;
                var add_1 = function (from, to, deco) {
                    return ranges_1.push(deco.range(from, to));
                };
                
                if (fromLine == toLine) {
                    console.warn("It migtht not works, since it did not implement it correctly #1");
                    console.log({
                        fromLine: fromLine,
                        toLine: toLine,
                        'view.state.doc':view.state.doc, 
                        'this_1.tag': this_1.tag, 
                        'start_1': start_1, 
                        'end_1': end_1
                    });
                    iterMatches(view.state.doc, this_1.tag, start_1, end_1, function (from, m) {
                        return _this.addMatch(m, view, from, add_1);
                    });
                   
             
                    /*this.tag.lastIndex = start - fromLine.from
                    while ((m = this.tag.exec(fromLine.text)) && m.index < end - fromLine.from)
                      this.addMatch(m, view, m.index + fromLine.from, add)*/

                    
                }
                else {
                    console.warn("It migtht not works, since it did not implement it correctly #2");
                    iterMatches(view.state.doc, this_1.tag, start_1, end_1, function (from, m) {
                        return _this.addMatch(m, view, from, add_1);
                    });
                }
                deco = deco.update({
                    filterFrom: start_1,
                    filterTo: end_1,
                    filter: function (from, to) { return from < start_1 || to > end_1; },
                    add: ranges_1
                });
            }
        };
        var this_1 = this;
        for (var _i = 0, _a = view.visibleRanges; _i < _a.length; _i++) {
            var r = _a[_i];
            _loop_2(r);
        }
        return deco;
    };
    return BallancedMatchDecorator2;
}());

export { BallancedMatchDecorator2 };
