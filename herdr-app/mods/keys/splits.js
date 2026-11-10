// Cmd+hjkl moves through nvim windows, then panes, then macOS windows
// (hammerspoon/init.lua); Alt+hjkl resizes the same way.
import { exec, hc } from "herdr";
import { app, focusedPane } from "./app.js";

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
  await app("pane.go", "--direction", dir);
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
// its near one, keeping each side at least 5% of the split. Resolves false
// when the pane spans the tab along that axis.
async function resizePane(pane, dir, step) {
  const path = pathTo((await tabTree(pane.tab)) ?? {}, pane.pane) ?? [];
  for (let i = path.length - 2; i >= 0; i--) {
    const kids = path[i].children;
    if (path[i].type !== SPLIT[dir] || kids.length < 2) continue;
    const at = kids.indexOf(path[i + 1]);
    const [a, b] = at < kids.length - 1 ? [kids[at], kids[at + 1]] : [kids[at - 1], kids[at]];
    const total = kids.reduce((sum, k) => sum + weight(k), 0);
    const want = (dir === "left" || dir === "up" ? -step : step) * total;
    const min = 0.05 * total;
    const delta = Math.max(min - weight(a), Math.min(weight(b) - min, want));
    if (delta * want > 0) {
      await app("layout.resize", JSON.stringify({ id: a.id, weight: weight(a) + delta }));
      await app("layout.resize", JSON.stringify({ id: b.id, weight: weight(b) - delta }));
    }
    return true;
  }
  return false;
}

// The focused pane, else the macOS window when the pane spans the tab or is zoomed.
async function resizeOutside(dir, fine, presses) {
  const pane = focusedPane();
  if (pane && !pane.zoomed && (await resizePane(pane, dir, (fine ? 0.01 : 0.03) * presses))) return;
  await hammerspoon(`resizeWindow('${dir}', ${fine ? 0.01 : "nil"}, ${presses})`);
}

async function resize(dir, fine, presses) {
  const nvim = nvimTerminal();
  if (nvim) {
    // nvim's own <M-hjkl> comes back as keys.resize-outside-<dir> without a split on that axis
    const key = `${fine ? "alt+shift" : "alt"}+${LETTER[dir]}`;
    await hc(["keys", nvim, ...Array(presses).fill(key)]);
    return;
  }
  await resizeOutside(dir, fine, presses);
}

export const COMMANDS = {};
// Take how many presses to apply at once
export const RESIZES = {};
for (const dir of Object.keys(LETTER)) {
  COMMANDS[`nav-${dir}`] = () => nav(dir);
  COMMANDS[`go-${dir}`] = () => go(dir);
  COMMANDS[`window-${dir}`] = () => hammerspoon(`focusWindow('${dir}')`);
  RESIZES[`resize-${dir}`] = (presses) => resize(dir, false, presses);
  RESIZES[`resize-${dir}-fine`] = (presses) => resize(dir, true, presses);
  RESIZES[`resize-outside-${dir}`] = (presses) => resizeOutside(dir, false, presses);
  RESIZES[`resize-outside-${dir}-fine`] = (presses) => resizeOutside(dir, true, presses);
}
