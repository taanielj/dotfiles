// tmux-style copy mode (mode-keys vi): prefix [ opens it over the focused
// terminal, on a snapshot of its screen and history. Move, search and select
// with the keyboard, y or Enter copies and leaves, q leaves.
import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { props, closeOverlay, theme, settings, focused, layout, panes, terminals, hc } from "herdr";
import { charWidth, clamp, firstNonBlank, search, selectedSpan, selectionText, tabBlock, wholeLine, wordBackward, wordEnd, wordForward, wrap } from "./motion.js";

const HISTORY_LINES = 2000;

const to = (target) => (v) => v.move(target(v));
const rows = (count) => (v) => v.move({ row: v.cursor.row + count, col: v.want }, true);
const scroll = (pages) => (v) => {
  const delta = Math.trunc(v.rows * pages);
  v.top += delta;
  v.move({ row: v.cursor.row + delta, col: v.want }, true);
};
const left = to((v) => ({ row: v.cursor.row, col: v.cursor.col - 1 }));
const right = to((v) => ({ row: v.cursor.row, col: v.cursor.col + charWidth(v.line, v.cursor.col) }));
const down = rows(1);
const up = rows(-1);
const lastRow = (v) => Math.min(v.lines.length, v.top + v.rows) - 1;

// tmux's copy-mode-vi keys. Looked up by chord ("ctrl-u", "pagedown"), then by
// the character the key types ("G", "$").
const KEYS = {
  h: left, left, j: down, down, k: up, up, l: right, right,
  w: to((v) => wordForward(v.lines, v.cursor)),
  b: to((v) => wordBackward(v.lines, v.cursor)),
  e: to((v) => wordEnd(v.lines, v.cursor)),
  0: to((v) => ({ row: v.cursor.row, col: 0 })),
  "^": to((v) => ({ row: v.cursor.row, col: firstNonBlank(v.line) })),
  $: (v) => v.move({ row: v.cursor.row, col: Infinity }, false, Infinity),
  g: to(() => ({ row: 0, col: 0 })),
  G: to((v) => ({ row: v.lines.length - 1, col: 0 })),
  "ctrl-u": scroll(-0.5), "ctrl-d": scroll(0.5),
  "ctrl-b": scroll(-1), "ctrl-f": scroll(1), pageup: scroll(-1), pagedown: scroll(1),
  H: to((v) => ({ row: v.top, col: 0 })),
  M: to((v) => ({ row: Math.floor((v.top + lastRow(v)) / 2), col: 0 })),
  L: to((v) => ({ row: lastRow(v), col: 0 })),
  "/": (v) => (v.prompt = { forward: true, text: "" }),
  "?": (v) => (v.prompt = { forward: false, text: "" }),
  n: (v) => v.find(true),
  N: (v) => v.find(false),
  v: (v) => v.select(false),
  V: (v) => v.select(true),
  space: (v) => (v.anchor = { ...v.cursor, linewise: false }),
  o: (v) => v.swapEnds(),
  y: (v, cx) => v.copy(cx),
  enter: (v, cx) => v.copy(cx),
  q: (v) => v.close(),
  escape: (v) => (v.anchor ? (v.anchor = null) : v.close()),
};

// A global ctrl-b in keys.json, such as a tmux-style prefix, would take the key.
// A binding in this view's own key context outranks it, so ctrl-b pages up here
// as it does in tmux.
const PAGE_UP = "copy-mode-page-up";
let pageUpBound = false;

// How wide one character of a font is at a size, measured once from a drawn
// string. The terminal rounds its cells to whole px, so its columns sit closer
// than the font's own spacing, and the text here is scaled to match.
const advances = {};
const MEASURED = "0".repeat(100);

export default class CopyMode extends View {
  init(_props, cx) {
    if (!pageUpBound) pageUpBound = cx.bind_keys([{ keystroke: "ctrl-b", action: PAGE_UP, context: "CopyMode" }]) > 0;
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.lines = null;
    this.size = null;
    this.cursor = { row: 0, col: 0 };
    this.want = 0;
    this.top = 0;
    this.anchor = null;
    this.prompt = null;
    this.query = null;
    this.message = "";
    const terminal = focused()?.terminal;
    if (!terminal) return this.close();
    this.terminal = terminal;
    cx.spawn(async (cx) => {
      const read = await hc(["read", terminal, "--json", "--lines", String(HISTORY_LINES)]);
      if (read.code !== 0) return this.close();
      const text = JSON.parse(read.stdout).text.replace(/\n$/, "").split("\n");
      ({ lines: this.lines, continued: this.continued } = wrap(text, this.grid?.cols || Infinity));
      this.start();
      cx.notify();
    });
  }

  // Runs once the text and the window size are both known: the view shows the
  // screen as it was, the cursor stands on its last line with text.
  start() {
    if (!this.lines || !this.size) return;
    this.top = Infinity;
    this.move({ row: Math.max(0, this.lines.findLastIndex((line) => line.trim())), col: 0 });
  }

  get line() {
    return this.lines[this.cursor.row];
  }

  // The terminal's entry in the core's list: its rows and cols.
  get grid() {
    return terminals().find((t) => t.address === this.terminal);
  }

  // Where to draw, in window px: over the focused pane's terminal when the tab
  // shows one pane, else over the whole tab. Herdr starts a terminal's grid at
  // its horizontal padding and centres it between the vertical ones (measured
  // on 0.1.15), so with one pane the rows and columns land where they were.
  get view() {
    const window = { x: 0, y: 0, width: this.size.width, height: this.size.height };
    const { rect, pane } = tabBlock(layout(), window) ?? { rect: window, pane: {} };
    const tab = panes().filter((p) => p.tab === focused()?.tab);
    const alone = tab.length === 1 || tab.some((p) => p.focused && p.zoomed);
    const framed = tab.length > 1 || pane.lone;
    const border = framed ? (pane.border?.width ?? 0) : 0;
    const header = framed && pane.header && pane.header.reveal !== "hover" ? (pane.header.height ?? 0) : 0;
    const headerOnTop = pane.header?.position !== "bottom";
    const [padX, padY] = settings().terminal_padding ?? [0, 0];
    const width = rect.width - 2 * border;
    const height = rect.height - 2 * border - header;
    const fontSize = settings().font_size;
    const grid = alone ? this.grid : null;
    const cell = (space, count, least, most) => {
      const size = Math.floor(space / (count || 1));
      return size >= fontSize * least && size <= fontSize * most ? size : null;
    };
    const lineHeight = cell(height - 2 * padY, grid?.rows, 1, 2) ?? Math.round(fontSize * 1.2);
    const rows = Math.max(1, Math.floor((height - 2 * padY) / lineHeight));
    return {
      x: rect.x + border,
      y: rect.y + border + (headerOnTop ? header : 0),
      width,
      height,
      padX,
      padTop: padY + Math.floor((height - 2 * padY - rows * lineHeight) / 2),
      cellWidth: cell(width - 2 * padX, grid?.cols, 0.4, 0.8),
      lineHeight,
      rows,
      radius: framed ? Math.max(0, (pane.radius ?? 0) - border) : 0,
      roundTop: !header || !headerOnTop,
      roundBottom: !header || headerOnTop,
    };
  }

  get rows() {
    return this.view.rows;
  }

  move(target, vertical = false, want = null) {
    this.cursor = clamp(this.lines, target);
    if (!vertical) this.want = want ?? this.cursor.col;
    const { rows } = this;
    const top = Math.max(0, Math.min(this.top, this.lines.length - rows));
    this.top = Math.min(Math.max(top, this.cursor.row - rows + 1), this.cursor.row);
  }

  select(linewise) {
    const again = this.anchor?.linewise === linewise;
    this.anchor = again ? null : { ...(this.anchor ?? this.cursor), linewise };
  }

  swapEnds() {
    if (!this.anchor) return;
    const { row, col, linewise } = this.anchor;
    this.anchor = { ...this.cursor, linewise };
    this.move({ row, col });
  }

  find(sameDirection) {
    if (!this.query) return;
    const found = search(this.lines, this.cursor, this.query.text, this.query.forward === sameDirection);
    if (found) this.move(found);
    else this.message = `no match: ${this.query.text}`;
  }

  copy(cx) {
    const { lines, continued, anchor, cursor } = this;
    cx.write_to_clipboard(anchor ? selectionText(lines, continued, anchor, cursor) : wholeLine(lines, continued, cursor.row));
    this.close();
  }

  // Shown outside an overlay (a layout block, `herdr-app check`) there is nothing to close.
  close() {
    const overlay = props()?.overlay;
    if (overlay) closeOverlay(overlay);
  }

  typeInPrompt(e) {
    const { prompt } = this;
    if (e.keystroke === "escape" || (e.keystroke === "backspace" && !prompt.text)) this.prompt = null;
    else if (e.keystroke === "backspace") prompt.text = prompt.text.slice(0, -1);
    else if (e.keystroke === "enter") {
      this.prompt = null;
      if (prompt.text) this.query = prompt;
      this.find(true);
    } else if (typed(e)) prompt.text += e.key_char;
  }

  press(e, cx) {
    cx.stop_propagation();
    if (!this.lines || !this.size) return e.keystroke === "escape" ? this.close() : undefined;
    this.message = "";
    if (this.prompt) this.typeInPrompt(e);
    else (KEYS[e.keystroke] ?? (typed(e) ? KEYS[e.key_char] : null))?.(this, cx);
    cx.notify();
  }

  row(index, t, lineHeight) {
    const line = this.lines[index];
    const span = selectedSpan(this.lines, this.anchor, this.cursor, index);
    const cursorCol = index === this.cursor.row ? this.cursor.col : -1;
    const el = h_flex().flex_none().h(lineHeight);
    if (!span && cursorCol < 0) return el.child(line);
    const paint = (piece, isCursor) => piece.bg(isCursor ? t.cursor : t.selection).text_color(t.background);
    if (!line) return el.child(paint(div().child(" "), cursorCol === 0));
    const cursorEnd = cursorCol + charWidth(line, cursorCol);
    const cuts = [...new Set([0, line.length, ...(span ?? []), ...(cursorCol < 0 ? [] : [cursorCol, cursorEnd])])].sort((a, b) => a - b);
    return el.children(
      cuts.slice(0, -1).map((from, i) => {
        const piece = div().flex_none().child(line.slice(from, cuts[i + 1]));
        if (from === cursorCol) return paint(piece, true);
        return span && from >= span[0] && cuts[i + 1] <= span[1] ? paint(piece, false) : piece;
      }),
    );
  }

  statusLine(t, v) {
    const bar = h_flex().absolute().right(0).top((v.rows - 1) * v.lineHeight).h(v.lineHeight).bg(t.background);
    if (this.prompt) {
      return bar.left(0).text_color(t.foreground)
        .child(`${this.prompt.forward ? "/" : "?"}${this.prompt.text}`)
        .child(div().bg(t.cursor).child(" "));
    }
    const mode = this.anchor ? (this.anchor.linewise ? "LINE" : "SELECT") : "COPY";
    return bar.px(6).bg(this.anchor ? t.selection : t.accent).text_color(t.background)
      .child(this.message || `${mode}  [${this.cursor.row + 1}/${this.lines.length}]`);
  }

  render() {
    const t = theme();
    const root = div()
      .id("copy-mode")
      .size_full()
      .track_focus(this.handle)
      .key_context("CopyMode")
      .on_action(PAGE_UP, (_e, cx) => this.press({ keystroke: "ctrl-b", modifiers: { control: true } }, cx))
      .on_key_down((e, cx) => this.press(e, cx))
      .on_mouse_down("left", (_e, cx) => {
        cx.stop_propagation();
        this.close();
      })
      .on_size_change((size, cx) => {
        this.size = size;
        this.start();
        cx.notify();
      });
    if (!this.lines || !this.size) return root;
    const v = this.view;
    const font = settings().font_family;
    const fontSize = settings().font_size;
    const measured = `${font} ${fontSize}`;
    const advance = advances[measured];
    const panel = div()
      .absolute().left(v.x).top(v.y).w(v.width).h(v.height)
      .pl(v.padX).pt(v.padTop)
      .overflow_hidden()
      .when(v.roundTop, (el) => el.rounded_t(v.radius))
      .when(v.roundBottom, (el) => el.rounded_b(v.radius))
      .bg(t.background)
      .text_color(t.terminal_foreground ?? t.foreground)
      .font_family(font)
      .text_size(advance && v.cellWidth ? (fontSize * v.cellWidth) / advance : fontSize)
      .line_height(`${v.lineHeight}px`)
      .whitespace_nowrap();
    if (!advance) {
      return root.child(
        panel.child(
          div().id("copy-mode-advance").absolute().opacity(0).child(MEASURED).on_size_change((size, cx) => {
            advances[measured] = size.width / MEASURED.length;
            cx.notify();
          }),
        ),
      );
    }
    const visible = this.lines.slice(this.top, this.top + v.rows);
    return root.child(
      panel.child(
        div().relative().size_full()
          .children(visible.map((_line, i) => this.row(this.top + i, t, v.lineHeight)))
          .child(this.statusLine(t, v)),
      ),
    );
  }
}

// The key types a character, rather than being a chord that happens to carry one.
function typed(e) {
  const { control, alt, platform } = e.modifiers;
  return Boolean(e.key_char) && e.key_char >= " " && !control && !alt && !platform;
}
