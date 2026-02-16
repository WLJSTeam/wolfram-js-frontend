import { WidgetType } from "@codemirror/view";
//credits https://github.com/fuermosi777

/**
 * Check if cursor is inside the widget.
 * @param update
 * @param from
 * @param to
 * @param inclusive Whether the left and right edges are included. Default is true.
 */
function isCursorInside(update, from, to, inclusive = true) {
  let latestTr = update.transactions[update.transactions.length - 1];
  if (latestTr && latestTr.selection) {
    if (
      inclusive &&
      latestTr.selection.main.head >= from &&
      latestTr.selection.main.head <= to
    ) {
      return true;
    }
    if (
      !inclusive &&
      latestTr.selection.main.head > from &&
      latestTr.selection.main.head < to
    ) {
      return true;
    }
  }
  return false;
}

/**
 * Check if cursor is inside the line.
 * @param state
 * @param from
 * @param to
 * @returns
 */
function isCursorInsideLine(state, from, to) {
  let cursorStart = state.selection.main.from;
  let cursorEnd = state.selection.main.to;
  if (from <= cursorStart && cursorStart <= to) {
    return true;
  }
  if (to <= cursorEnd && cursorEnd <= to) {
    return true;
  }
  return false;
}

function eachLineMatchRe(
  doc,
  from,
  // TODO: use this to save cost.
  to,
  re,
  func
) {
  for (let pos = from, iter = doc.iterRange(from), m; !iter.next().done; ) {
    if (!iter.lineBreak) {
      while ((m = re.exec(iter.value))) {
        func(m, pos);
      }
    }
    pos += iter.value.length + 1;
  }
}

class EmptyWidget extends WidgetType {
  constructor() {
    super();
  }

  eq(_) {
    return true;
  }

  toDOM() {
    let span = document.createElement("span");
    return span;
  }

  ignoreEvent() {
    return false;
  }
}

export { isCursorInside, isCursorInsideLine, eachLineMatchRe, EmptyWidget };
