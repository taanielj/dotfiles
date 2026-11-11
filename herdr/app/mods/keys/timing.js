// Debug timing for the key path, written to ~/.config/herdr-app/keys-timing.log
// as "<epoch ms> <label>". nvim/lua/lib/splits.lua writes keys-timing-nvim.log.
import * as fs from "fs/promises";
import { appHome, exec } from "herdr";

const PATH = `${appHome()}/keys-timing.log`;
const MAX_LINES = 2000;
const lines = [];
let writes = Promise.resolve();

export function mark(label) {
  lines.push(`${Date.now()} ${label}`);
  if (lines.length > MAX_LINES) lines.splice(0, lines.length - MAX_LINES);
  // Each write replaces the file with the buffer, because the fs API has no append
  writes = writes
    .then(() => fs.writeFile(PATH, lines.join("\n") + "\n"))
    .catch((e) => exec("sh", ["-c", 'echo "$1" >> "$2"', "sh", String(e), `${PATH}.error`]));
}

export async function timed(label, run) {
  const start = Date.now();
  try {
    return await run();
  } finally {
    mark(`${label} ${Date.now() - start}ms`);
  }
}
