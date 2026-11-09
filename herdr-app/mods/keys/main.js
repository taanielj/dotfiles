// Key commands the app has no single command for, bound in keys.json as
// keys.<command>: Cmd+hjkl moves through nvim windows, then panes, then macOS
// windows (hammerspoon/init.lua); Alt+hjkl resizes the same way; the rest are
// herdr's prefix keys that open a picker, an editor or lazygit in a dialog, or
// move a pane to another tab. The layout docks this mod in a zero-width block
// because commands reach only a shown copy.
import { View, div } from "gpui-kit";
import { appHome, exec, focused, hc, nextCommand, openOverlay, panes, spaces } from "herdr";
import * as fs from "fs/promises";

const LETTER = { left: "h", down: "j", up: "k", right: "l" };

// Prints what Hammerspoon returns for the Lua. While Hammerspoon isn't
// running, `hs` hangs rather than fails; this fails instead and relaunches it.
async function hammerspoon(lua) {
  if ((await exec("pgrep", ["-xq", "Hammerspoon"])).code !== 0) {
    await exec("open", ["-g", "-a", "Hammerspoon"]);
    return false;
  }
  const r = await exec("hs", ["-c", lua], { timeout: 2000 });
  return r.stdout.trim() === "true";
}

function focusedPane() {
  const id = focused()?.pane;
  return panes().find((p) => p.pane === id) ?? null;
}

// The terminal that has the keyboard, when it runs nvim.
function nvimTerminal() {
  const pane = focusedPane();
  return pane?.program.key === "nvim" ? pane.terminal : null;
}

// The window's focused pane, read through the CLI: run() applies after it returns.
async function focusedPaneNow() {
  const r = await exec("herdr-app", ["status"]);
  return JSON.parse(r.stdout).focused_pane;
}

// The next pane that way, else the next macOS window.
async function go(dir) {
  const before = await focusedPaneNow();
  await exec("herdr-app", ["do", "pane.go", "--direction", dir]);
  if ((await focusedPaneNow()) === before) {
    await hammerspoon(`focusWindow('${dir}')`);
  }
}

async function nav(dir) {
  const nvim = nvimTerminal();
  if (nvim) {
    // nvim's own <C-hjkl> comes back as keys.go-<dir> at its edge (nvim/lua/lib/splits.lua)
    await hc(["keys", nvim, `ctrl+${LETTER[dir]}`]);
    return;
  }
  await go(dir);
}

const SPLIT = { left: "row", right: "row", up: "column", down: "column" };

// A tab's split tree as the app keeps it in herdr-core's herdr-app document;
// the app's own commands don't expose it.
async function tabTree(tab) {
  const get = '{"jsonrpc":"2.0","id":1,"method":"doc.get","params":{"name":"herdr-app"}}';
  const r = await exec("sh", ["-c", 'printf "%s\\n" "$1" | hc connect', "sh", get]);
  const doc = JSON.parse(r.stdout).result.value;
  return doc.spaces.flatMap((s) => s.tabs).find((t) => t.id === tab)?.root ?? null;
}

function pathTo(node, id) {
  if (node.id === id) return [node];
  for (const child of node.children ?? []) {
    const path = pathTo(child, id);
    if (path) return [node, ...path];
  }
  return null;
}

const weight = (node) => node.size?.weight ?? 1;

// Moves the border of the pane's branch in the nearest split that runs that
// way, like smart-splits: its far border when it has a neighbour there, else
// its near one. Resolves false when the pane spans the tab along that axis.
async function resizePane(pane, dir, step) {
  const path = pathTo((await tabTree(pane.tab)) ?? {}, pane.pane) ?? [];
  for (let i = path.length - 2; i >= 0; i--) {
    const kids = path[i].children;
    if (path[i].type !== SPLIT[dir] || kids.length < 2) continue;
    const at = kids.indexOf(path[i + 1]);
    const [a, b] = at < kids.length - 1 ? [kids[at], kids[at + 1]] : [kids[at - 1], kids[at]];
    const total = kids.reduce((sum, k) => sum + weight(k), 0);
    const delta = (dir === "left" || dir === "up" ? -step : step) * total;
    const [wa, wb] = [weight(a) + delta, weight(b) - delta];
    if (Math.min(wa, wb) >= 0.05 * total) {
      await app("layout.resize", JSON.stringify({ id: a.id, weight: wa }));
      await app("layout.resize", JSON.stringify({ id: b.id, weight: wb }));
    }
    return true;
  }
  return false;
}

// The focused pane, else the macOS window when the pane spans the tab or is zoomed.
async function resizeOutside(dir, fine) {
  const pane = focusedPane();
  if (pane && !pane.zoomed && (await resizePane(pane, dir, fine ? 0.01 : 0.03))) return;
  await hammerspoon(`resizeWindow('${dir}', ${fine ? 0.01 : "nil"})`);
}

async function resize(dir, fine) {
  const nvim = nvimTerminal();
  if (nvim) {
    // nvim's own <M-hjkl> comes back as keys.resize-outside-<dir> without a split on that axis
    await hc(["keys", nvim, `${fine ? "alt+shift" : "alt"}+${LETTER[dir]}`]);
    return;
  }
  await resizeOutside(dir, fine);
}

const sleep = (cx, ms) => new Promise((done) => cx.timer.after(ms, () => done()));

// Runs argv in a terminal shown in a dialog; resolves once it exits.
async function dialog(cx, argv, { cwd, size = 0.6 } = {}) {
  const args = ["run", "--bg", "--json", "--no-parent", "--rm"];
  if (cwd) args.push("--cwd", cwd);
  const { address } = JSON.parse((await hc([...args, "--", ...argv])).stdout);
  // The dialog closes itself when its terminal ends
  openOverlay({ kind: "dialog", width: size, height: size, layout: { type: "block", content: { terminal: address } } });
  // Asked of the core: terminals() lists a new terminal only a moment later.
  // --rm removes it once it exits, and hc get then fails.
  for (;;) {
    const r = await hc(["get", address, "--json"]);
    if (r.code !== 0 || JSON.parse(r.stdout).state !== "live") break;
    await sleep(cx, 300);
  }
}

function dataDir() {
  return `${appHome()}/data/keys`;
}

// fzf over panes with a preview of each one's screen; resolves to the picked
// terminal, or null when cancelled.
async function pickTerminal(cx, prompt, keep) {
  const tabs = new Map(spaces().flatMap((s) => s.tabs.map((t) => [t.id, `${s.name} · ${t.index}:${t.name}`])));
  const rows = panes()
    .filter((p) => p.terminal && keep(p))
    .map((p) => `${p.terminal}\t${tabs.get(p.tab) ?? "?"}  ${(p.cwd ?? "").split("/").pop()}  ${p.title || p.program.name}`);
  if (rows.length === 0) return null;
  await fs.mkdir(dataDir(), { recursive: true });
  const list = `${dataDir()}/panes.tsv`;
  const out = `${dataDir()}/picked`;
  await fs.writeFile(list, rows.join("\n") + "\n");
  await fs.writeFile(out, "");
  await dialog(cx, ["sh", "-c",
    'fzf --height=100% --with-nth=2.. --delimiter="\t" --prompt="$1" --preview "hc read {1}" --preview-window=down,50% <"$2" | cut -f1 >"$3"',
    "sh", prompt, list, out]);
  return (await fs.readFile(out, "utf8")).trim() || null;
}

// Gives a terminal a new pane: a new tab, or right or down of the focused pane.
// Keep waits for the park (taking its pane away), which lands asynchronously.
async function movePane(cx, terminal, place) {
  await exec("herdr-app", ["do", "terminal.park", "--terminal", terminal]);
  for (let i = 0; i < 100 && panes().some((p) => p.terminal === terminal); i++) {
    await sleep(cx, 50);
  }
  const kept = await exec("herdr-app", ["do", "terminal.keep", "--terminal", terminal, "--place", place]);
  if (place === "tab") {
    // A new tab is named after its terminal's address; "" shows its number
    await exec("herdr-app", ["do", "tab.rename", JSON.stringify({ id: JSON.parse(kept.stdout).tab, name: "" })]);
  }
}

async function goto(cx) {
  const here = focused()?.pane;
  const terminal = await pickTerminal(cx, "goto > ", (p) => p.pane !== here);
  if (terminal) await exec("herdr-app", ["do", "pane.focus", "--terminal", terminal]);
}

// Pulls a pane from another tab in beside the focused one.
async function join(cx, place) {
  const tab = focused()?.tab;
  const terminal = await pickTerminal(cx, `join pane (${place}) > `, (p) => p.tab !== tab);
  if (terminal) await movePane(cx, terminal, place);
}

async function breakPane(cx) {
  const terminal = focused()?.terminal;
  if (terminal) await movePane(cx, terminal, "tab");
}

// The focused terminal's history in nvim, unless it has none above its screen
// (a full-screen program such as nvim, or an agent that redraws its view).
async function scrollback(cx) {
  const terminal = focused()?.terminal;
  if (!terminal) return;
  const screen = (await hc(["read", terminal])).stdout;
  const all = (await hc(["read", terminal, "--lines", "100000"])).stdout;
  if (all.length <= screen.length) return;
  await fs.mkdir(dataDir(), { recursive: true });
  const file = `${dataDir()}/scrollback.txt`;
  await fs.writeFile(file, all);
  await dialog(cx, ["nvim", "+", file], { size: 0.9 });
}

async function lazygit(cx) {
  await dialog(cx, ["lazygit"], { cwd: focused()?.cwd ?? undefined, size: 0.9 });
}

// tmux's layouts, in the order prefix+space cycles them (herdr-pane-layouts' order)
const LAYOUTS = ["even-horizontal", "even-vertical", "main-vertical", "main-horizontal", "tiled"];

async function app(...args) {
  return JSON.parse((await exec("herdr-app", ["do", ...args])).stdout || "{}");
}

async function waitFor(cx, done) {
  for (let i = 0; i < 100 && !done(); i++) await sleep(cx, 50);
}

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

// nvim's zen mode (nvim/lua/lib/mux.lua): the focused pane zoomed and the
// window's bars hidden, until zen-out puts back what zen-in found.
const BARS = ["sidebar", "tabs", "status"];
let zenZoomed = null;

async function zenIn() {
  zenZoomed = focusedPane()?.zoomed ?? false;
  if (!zenZoomed) await app("pane.zoom");
  for (const id of BARS) await app("layout.hide", "--id", id);
}

async function zenOut() {
  for (const id of BARS) await app("layout.show", "--id", id);
  if (zenZoomed === false && focusedPane()?.zoomed) await app("pane.zoom");
  zenZoomed = null;
}

// Commands that wait on a dialog run as their own task to keep navigation working.
const DIALOGS = {
  "pick-goto": goto,
  "pick-join-right": (cx) => join(cx, "right"),
  "pick-join-down": (cx) => join(cx, "down"),
  "scrollback": scrollback,
  "lazygit": lazygit,
};

const COMMANDS = {
  "break": breakPane,
  "layout-next": nextLayout,
  "zen-in": zenIn,
  "zen-out": zenOut,
};
for (const dir of Object.keys(LETTER)) {
  COMMANDS[`nav-${dir}`] = () => nav(dir);
  COMMANDS[`go-${dir}`] = () => go(dir);
  COMMANDS[`window-${dir}`] = () => hammerspoon(`focusWindow('${dir}')`);
  COMMANDS[`resize-${dir}`] = () => resize(dir, false);
  COMMANDS[`resize-${dir}-fine`] = () => resize(dir, true);
  COMMANDS[`resize-outside-${dir}`] = () => resizeOutside(dir, false);
  COMMANDS[`resize-outside-${dir}-fine`] = () => resizeOutside(dir, true);
}

export default class Keys extends View {
  init(_props, cx) {
    const report = (command) => (e) => console.log(`keys.${command}: ${e}`);
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (DIALOGS[command]) {
          cx.spawn((cx) => DIALOGS[command](cx).catch(report(command)));
        } else if (COMMANDS[command]) {
          await COMMANDS[command](cx).catch(report(command));
        }
      }
    });
  }

  render() {
    return div();
  }
}
