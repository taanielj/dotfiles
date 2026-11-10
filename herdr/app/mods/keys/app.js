import { exec, focused, panes } from "herdr";

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
