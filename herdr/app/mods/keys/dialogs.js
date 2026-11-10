// herdr's prefix keys that open a picker, an editor or lazygit in a dialog, or
// move a pane to another tab.
import { appHome, focused, hc, openOverlay, panes, spaces } from "herdr";
import * as fs from "fs/promises";
import { app, sleep, waitFor } from "./app.js";

async function runInDialog(cx, argv, { cwd, size = 0.6 } = {}) {
  const args = ["run", "--bg", "--json", "--no-parent", "--rm"];
  if (cwd) args.push("--cwd", cwd);
  const { address } = JSON.parse((await hc([...args, "--", ...argv])).stdout);
  // The dialog closes itself when its terminal ends
  openOverlay({ kind: "dialog", width: size, height: size, layout: { type: "block", content: { terminal: address } } });
  // Polls with the herdr core CLI's `hc get`, because the mod API's terminals() lists a new terminal only
  // after a delay. --rm removes the terminal once it exits, which makes hc get fail.
  for (;;) {
    const r = await hc(["get", address, "--json"]);
    if (r.code !== 0 || JSON.parse(r.stdout).state !== "live") break;
    await sleep(cx, 300);
  }
}

function dataDir() {
  return `${appHome()}/data/keys`;
}

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
  await runInDialog(cx, ["sh", "-c",
    'fzf --height=100% --with-nth=2.. --delimiter="\t" --prompt="$1" --preview "hc read {1}" --preview-window=down,50% <"$2" | cut -f1 >"$3"',
    "sh", prompt, list, out]);
  return (await fs.readFile(out, "utf8")).trim() || null;
}

async function moveToNewPane(cx, terminal, place) {
  await app("terminal.park", "--terminal", terminal);
  // terminal.park removes the pane asynchronously, and terminal.keep needs it gone
  await waitFor(cx, () => !panes().some((p) => p.terminal === terminal));
  const { tab } = await app("terminal.keep", "--terminal", terminal, "--place", place);
  if (place === "tab") {
    // A new tab is named after its terminal's address; "" shows its number
    await app("tab.rename", JSON.stringify({ id: tab, name: "" }));
  }
}

async function goto(cx) {
  const here = focused()?.pane;
  const terminal = await pickTerminal(cx, "goto > ", (p) => p.pane !== here);
  if (terminal) await app("pane.focus", "--terminal", terminal);
}

async function join(cx, place) {
  const tab = focused()?.tab;
  const terminal = await pickTerminal(cx, `join pane (${place}) > `, (p) => p.tab !== tab);
  if (terminal) await moveToNewPane(cx, terminal, place);
}

async function breakPane(cx) {
  const terminal = focused()?.terminal;
  if (terminal) await moveToNewPane(cx, terminal, "tab");
}

async function scrollback(cx) {
  const terminal = focused()?.terminal;
  if (!terminal) return;
  const screen = (await hc(["read", terminal])).stdout;
  const all = (await hc(["read", terminal, "--lines", "100000"])).stdout;
  // A full-screen program such as nvim, or an agent that redraws its view, has no
  // history above its screen
  if (all.length <= screen.length) return;
  await fs.mkdir(dataDir(), { recursive: true });
  const file = `${dataDir()}/scrollback.txt`;
  await fs.writeFile(file, all);
  await runInDialog(cx, ["nvim", "+", file], { size: 0.9 });
}

async function lazygit(cx) {
  await runInDialog(cx, ["lazygit"], { cwd: focused()?.cwd ?? undefined, size: 0.9 });
}

// The dialog's terminal outlives the spaces the sync closes, because it sits outside every space
async function syncFromTui(cx) {
  await runInDialog(cx, ["herdr-sync", "app"]);
}

export const DIALOGS = {
  "pick-goto": goto,
  "pick-join-right": (cx) => join(cx, "right"),
  "pick-join-down": (cx) => join(cx, "down"),
  "scrollback": scrollback,
  "lazygit": lazygit,
  "sync-from-tui": syncFromTui,
};

export const COMMANDS = { "break": breakPane };
