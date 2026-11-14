import { exec, focused, machines, panes, spaces, window } from "herdr";

export const onMac = () => window()?.platform === "macos";
export const onWindows = () => window()?.platform === "windows";

// "wsl/t8" -> "wsl"; null for this computer's ids
export const machineOf = (id) => (id?.includes("/") ? id.split("/")[0] : null);
// "wsl/t8" -> "t8", as that machine's core has it
export const localId = (id) => id?.split("/").pop();

// Where shell tools run: on Windows a machine (WSL), else this computer
export function shellMachine() {
  if (!onWindows()) return null;
  const space = spaces().find((s) => s.id === focused()?.space);
  return space?.machine ?? machines().find((m) => m.name)?.name ?? null;
}

// A path on this computer as shellMachine() reaches it: C:\x -> /mnt/c/x
export function shellPath(path) {
  if (!onWindows() || !path) return path;
  return path.replace(/\\/g, "/").replace(/^([A-Za-z]):/, (_, d) => `/mnt/${d.toLowerCase()}`);
}

export const sleep = (cx, ms) => new Promise((done) => cx.timer.after(ms, () => done()));

export async function waitFor(cx, done) {
  for (let i = 0; i < 100 && !done(); i++) await sleep(cx, 50);
}

// Runs an app command through the herdr-app CLI and resolves once the command has
// applied. The mod API's run() would apply the command only after the current mod
// command returns.
export async function app(...args) {
  return JSON.parse((await exec("herdr-app", ["do", ...args])).stdout || "{}");
}

export function pathTo(node, id) {
  if (node.id === id) return [node];
  for (const child of node.children ?? []) {
    const path = pathTo(child, id);
    if (path) return [node, ...path];
  }
  return null;
}

export function focusedPane() {
  const id = focused()?.pane;
  return panes().find((p) => p.pane === id) ?? null;
}
