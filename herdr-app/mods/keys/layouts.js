// prefix+space: tmux's layouts for the focused tab.
import { focused, panes } from "herdr";
import { app, waitFor } from "./app.js";

// tmux's layouts, in the order prefix+space cycles them (herdr-pane-layouts' order)
const LAYOUTS = ["even-horizontal", "even-vertical", "main-vertical", "main-horizontal", "tiled"];

async function focusPane(cx, pane) {
  await app("pane.focus", "--pane", pane);
  await waitFor(cx, () => focused()?.pane === pane);
}

// Gives each parked terminal a pane right or down of the one before, starting
// beside `from`; resolves to every pane in the line, `from` first, sized evenly.
async function line(cx, from, terminals, place) {
  await focusPane(cx, from);
  const ids = [from];
  for (const terminal of terminals) {
    // The next one goes beside the new pane, which takes the focus
    const { pane } = await app("terminal.keep", "--terminal", terminal, "--place", place);
    await waitFor(cx, () => focused()?.pane === pane);
    ids.push(pane);
  }
  for (const id of ids) await app("layout.resize", JSON.stringify({ id, weight: 1 }));
  return ids;
}

// Rebuilds the focused tab in the next layout: every pane but the first is
// parked, then given a pane again in its place. Terminals keep running.
async function nextLayout(cx) {
  const { tab, terminal: here } = focused() ?? {};
  const order = panes().filter((p) => p.tab === tab && p.terminal);
  if (order.length < 2) return;
  const key = `layout:${tab}`;
  const layout = LAYOUTS[(LAYOUTS.indexOf(localStorage.getItem(key)) + 1) % LAYOUTS.length];
  localStorage.setItem(key, layout);

  const first = order[0].pane;
  const rest = order.slice(1).map((p) => p.terminal);
  for (const terminal of rest) await app("terminal.park", "--terminal", terminal);
  await waitFor(cx, () => !panes().some((p) => rest.includes(p.terminal)));

  const [second, ...more] = rest;
  if (layout === "even-horizontal") await line(cx, first, rest, "right");
  if (layout === "even-vertical") await line(cx, first, rest, "down");
  if (layout === "main-vertical") await line(cx, (await line(cx, first, [second], "right"))[1], more, "down");
  if (layout === "main-horizontal") await line(cx, (await line(cx, first, [second], "down"))[1], more, "right");
  if (layout === "tiled") {
    const cols = Math.ceil(Math.sqrt(order.length));
    const rows = [];
    for (let i = 0; i < rest.length + 1; i += cols) rows.push([first, ...rest].slice(i, i + cols));
    const starts = await line(cx, first, rows.slice(1).map((r) => r[0]), "down");
    for (const [i, row] of rows.entries()) await line(cx, starts[i], row.slice(1), "right");
  }
  if (here) await app("pane.focus", "--terminal", here);
}

export const COMMANDS = { "layout-next": nextLayout };
