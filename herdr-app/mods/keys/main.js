// Key commands that need a decision before acting, bound in keys.json as
// keys.<command>: Cmd+hjkl moves through nvim windows, then panes, then macOS
// windows (hammerspoon/init.lua); Alt+hjkl resizes the same way. The layout
// docks this mod in a zero-width block because commands reach only a shown copy.
import { View, div } from "gpui-kit";
import { exec, focused, hc, nextCommand, panes } from "herdr";

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

// A pane alone in its tab, or zoomed, resizes the macOS window.
async function resizeOutside(dir, fine) {
  const pane = focusedPane();
  if (!pane || pane.zoomed || panes().filter((p) => p.tab === pane.tab).length === 1) {
    await hammerspoon(`resizeWindow('${dir}', ${fine ? 0.01 : "nil"})`);
  }
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

const COMMANDS = {};
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
    cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        try {
          await COMMANDS[command]?.();
        } catch (e) {
          console.log(`keys.${command}: ${e}`);
        }
      }
    });
  }

  render() {
    return div();
  }
}
