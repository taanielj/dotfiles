import { layout } from "herdr";
import { app, focusedPane, pathTo } from "./app.js";

// nvim's zen mode runs zen-in and zen-out (nvim/lua/lib/mux.lua).
const BARS = ["sidebar", "tabs", "status", "panel"];
// Replaces the tab bar to keep the pane below macOS's window buttons
const STRIP = "zen-strip";
const ZEN_IN_STATE_KEY = "zen"; // localStorage keeps the state across a mod reload

async function zenIn() {
  const root = layout();
  const shown = BARS.filter((id) => {
    const node = pathTo(root, id)?.at(-1);
    return node && !node.hidden;
  });
  const zoomed = focusedPane()?.zoomed ?? false;
  localStorage.setItem(ZEN_IN_STATE_KEY, JSON.stringify({ shown, zoomed }));
  if (!zoomed) await app("pane.zoom");
  for (const id of shown) await app("layout.hide", "--id", id);
  await app("layout.show", "--id", STRIP);
}

async function zenOut() {
  const { shown = [], zoomed = true } = JSON.parse(localStorage.getItem(ZEN_IN_STATE_KEY) ?? "{}");
  localStorage.removeItem(ZEN_IN_STATE_KEY);
  await app("layout.hide", "--id", STRIP);
  for (const id of shown) await app("layout.show", "--id", id);
  if (!zoomed && focusedPane()?.zoomed) await app("pane.zoom");
}

export const COMMANDS = { "zen-in": zenIn, "zen-out": zenOut };
