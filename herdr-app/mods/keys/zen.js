import { app, focusedPane } from "./app.js";

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

export const COMMANDS = { "zen-in": zenIn, "zen-out": zenOut };
