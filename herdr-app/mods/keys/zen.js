import { layout } from "herdr";
import { app, focusedPane, pathTo } from "./app.js";

// nvim's zen mode (nvim/lua/lib/mux.lua): the focused pane zoomed and the
// window's bars and Files/Changes panel hidden, until zen-out puts back what
// zen-in found. A bare strip takes the tab bar's place, keeping the pane clear
// of macOS's window buttons.
const BARS = ["sidebar", "tabs", "status", "panel"];
const STRIP = "zen-strip";
// What zen-in found, kept in storage so a mod reload doesn't lose it
const FOUND = "zen";

async function zenIn() {
  const root = layout();
  const shown = BARS.filter((id) => {
    const node = pathTo(root, id)?.at(-1);
    return node && !node.hidden;
  });
  const zoomed = focusedPane()?.zoomed ?? false;
  localStorage.setItem(FOUND, JSON.stringify({ shown, zoomed }));
  if (!zoomed) await app("pane.zoom");
  for (const id of shown) await app("layout.hide", "--id", id);
  await app("layout.show", "--id", STRIP);
}

async function zenOut() {
  const { shown = [], zoomed = true } = JSON.parse(localStorage.getItem(FOUND) ?? "{}");
  localStorage.removeItem(FOUND);
  await app("layout.hide", "--id", STRIP);
  for (const id of shown) await app("layout.show", "--id", id);
  if (!zoomed && focusedPane()?.zoomed) await app("pane.zoom");
}

export const COMMANDS = { "zen-in": zenIn, "zen-out": zenOut };
