// Pure cursor, selection, search and layout logic for copy mode, kept free of
// Herdr imports so node can test it. `lines` are screen rows: a line wider
// than the terminal is split by `wrap`, and `continued` holds the rows that
// carry on from the row above. A position is { row, col }, col counted in
// UTF-16 units. Each row also has one virtual blank cell at col === length,
// which is how an empty row gets a place for the cursor to stand.

const BLANK = 0;
const WORD = 1;
const PUNCT = 2;

function kind(ch) {
  if (ch === undefined || /\s/.test(ch)) return BLANK;
  return /[\p{L}\p{N}_]/u.test(ch) ? WORD : PUNCT;
}

const at = (lines, p) => lines[p.row][p.col];
const emptyLine = (lines, p) => lines[p.row].length === 0;

function next(lines, p) {
  if (p.col < lines[p.row].length) return { row: p.row, col: p.col + 1 };
  return p.row + 1 < lines.length ? { row: p.row + 1, col: 0 } : null;
}

function prev(lines, p) {
  if (p.col > 0) return { row: p.row, col: p.col - 1 };
  return p.row > 0 ? { row: p.row - 1, col: lines[p.row - 1].length } : null;
}

const isLowSurrogate = (line, col) => (line.charCodeAt(col) & 0xfc00) === 0xdc00;

// How many UTF-16 units the character under `col` takes.
export function charWidth(line, col) {
  return (line.charCodeAt(col) & 0xfc00) === 0xd800 && col + 1 < line.length ? 2 : 1;
}

// The nearest place the cursor may stand: on a character, never past the last
// one, never on the second half of a surrogate pair.
export function clamp(lines, { row, col }) {
  const r = Math.max(0, Math.min(lines.length - 1, row));
  const line = lines[r];
  let c = Math.max(0, Math.min(line.length - 1, col));
  if (c > 0 && isLowSurrogate(line, c)) c -= 1;
  return { row: r, col: c };
}

// `hc read` joins soft-wrapped rows back into one line. This splits them again
// at the terminal's width, so the rows match what the screen showed.
export function wrap(text, cols) {
  const lines = [];
  const continued = new Set();
  for (const line of text) {
    let from = 0;
    do {
      let end = Math.min(line.length, from + cols);
      if (end < line.length && end - from > 1 && isLowSurrogate(line, end)) end -= 1;
      if (from > 0) continued.add(lines.length);
      lines.push(line.slice(from, end));
      from = end;
    } while (from < line.length);
  }
  return { lines, continued };
}

// The whole line a row belongs to, wrapped parts joined.
export function wholeLine(lines, continued, row) {
  let first = row;
  let last = row;
  while (continued.has(first)) first -= 1;
  while (continued.has(last + 1)) last += 1;
  return lines.slice(first, last + 1).join("");
}

export function lastPosition(lines) {
  return clamp(lines, { row: lines.length - 1, col: Infinity });
}

export function firstNonBlank(line) {
  const col = line.search(/\S/);
  return col < 0 ? 0 : col;
}

// vi's `w`: the start of the next word, where an empty line counts as a word.
export function wordForward(lines, pos) {
  let p = pos;
  const k = kind(at(lines, p));
  if (k !== BLANK) while (p && kind(at(lines, p)) === k) p = next(lines, p);
  while (p && kind(at(lines, p)) === BLANK && !(emptyLine(lines, p) && p.row !== pos.row)) p = next(lines, p);
  return p ?? lastPosition(lines);
}

// vi's `b`: the start of this word, or of the previous one.
export function wordBackward(lines, pos) {
  let p = prev(lines, pos);
  while (p && kind(at(lines, p)) === BLANK && !emptyLine(lines, p)) p = prev(lines, p);
  if (!p) return { row: 0, col: 0 };
  if (emptyLine(lines, p)) return p;
  const k = kind(at(lines, p));
  for (;;) {
    const q = prev(lines, p);
    if (!q || q.row !== p.row || kind(at(lines, q)) !== k) return p;
    p = q;
  }
}

// vi's `e`: the end of this word, or of the next one.
export function wordEnd(lines, pos) {
  let p = next(lines, pos);
  while (p && kind(at(lines, p)) === BLANK) p = next(lines, p);
  if (!p) return lastPosition(lines);
  const k = kind(at(lines, p));
  for (;;) {
    const q = next(lines, p);
    if (!q || kind(at(lines, q)) !== k) return p;
    p = q;
  }
}

const before = (a, b) => a.row < b.row || (a.row === b.row && a.col <= b.col);

// The selected columns of `row` as a half-open [from, to), or null. An anchor
// is { row, col, linewise }; the selection runs from it to the cursor, both
// ends included, as vi's visual mode does.
export function selectedSpan(lines, anchor, cursor, row) {
  if (!anchor) return null;
  const [start, end] = before(anchor, cursor) ? [anchor, cursor] : [cursor, anchor];
  if (row < start.row || row > end.row) return null;
  const line = lines[row];
  if (anchor.linewise) return [0, line.length];
  const from = row === start.row ? start.col : 0;
  const to = row === end.row ? Math.min(line.length, end.col + charWidth(line, end.col)) : line.length;
  return [from, to];
}

// The selected text. Rows of one wrapped line join without a line break.
export function selectionText(lines, continued, anchor, cursor) {
  const [start, end] = before(anchor, cursor) ? [anchor, cursor] : [cursor, anchor];
  let out = "";
  for (let row = start.row; row <= end.row; row++) {
    if (row > start.row && !continued.has(row)) out += "\n";
    out += lines[row].slice(...selectedSpan(lines, anchor, cursor, row));
  }
  return out;
}

// The next match of `query` strictly after `pos` (or before it), wrapping
// around the buffer. As in tmux, an all-lowercase query ignores case.
export function search(lines, pos, query, forward) {
  if (!query) return null;
  const fold = query === query.toLowerCase();
  const text = (row) => (fold ? lines[row].toLowerCase() : lines[row]);
  const n = lines.length;
  for (let i = 0; i <= n; i++) {
    const row = (pos.row + (forward ? i : -i) + n * 2) % n;
    const line = text(row);
    let col;
    if (forward) col = line.indexOf(query, i === 0 ? pos.col + 1 : 0);
    else if (i === 0) col = pos.col === 0 ? -1 : line.lastIndexOf(query, pos.col - 1);
    else col = line.lastIndexOf(query);
    if (col >= 0) return { row, col };
  }
  return null;
}

// Where a layout tree (layouts/<name>.json, as `layout()` returns it) puts the
// block showing the active tab, in window px, with that block's pane frame.
// Herdr gives mods no pane geometry, so this follows the same sizing rules:
// px sizes are fixed, the rest is shared by weight, hidden nodes take nothing.
export function tabBlock(node, rect) {
  if (!node || node.hidden) return null;
  if (node.content?.tab) return { rect, pane: node.content.pane ?? {} };
  const children = (node.children ?? []).filter((c) => !c.hidden);
  if (!children.length) return null;
  const [py, px] = Array.isArray(node.padding) ? node.padding : [node.padding ?? 0, node.padding ?? 0];
  const inner = { x: rect.x + px, y: rect.y + py, width: rect.width - 2 * px, height: rect.height - 2 * py };
  if (node.type === "stack") return tabBlock(children.find((c) => c.id === node.active) ?? children[0], inner);
  const across = node.type === "row";
  const between = (node.gap ?? 0) + (node.divider?.width ?? 0);
  const fixed = children.reduce((sum, c) => sum + (c.size?.px ?? 0), 0);
  const weights = children.reduce((sum, c) => sum + (c.size?.px === undefined ? (c.size?.weight ?? 1) : 0), 0);
  const free = (across ? inner.width : inner.height) - between * (children.length - 1) - fixed;
  let offset = across ? inner.x : inner.y;
  for (const c of children) {
    const length = c.size?.px ?? (free * (c.size?.weight ?? 1)) / weights;
    const found = tabBlock(c, across ? { ...inner, x: offset, width: length } : { ...inner, y: offset, height: length });
    if (found) return found;
    offset += length + between;
  }
  return null;
}
