// Key commands the app has no single command for, bound in keys.json as
// keys.<command>. The layout docks this mod in a zero-width block because
// commands reach only a shown copy.
import { View, div } from "gpui-kit";
import { nextCommand } from "herdr";
import * as dialogs from "./dialogs.js";
import * as layouts from "./layouts.js";
import * as splits from "./splits.js";
import * as zen from "./zen.js";

const COMMANDS = { ...dialogs.COMMANDS, ...layouts.COMMANDS, ...splits.COMMANDS, ...zen.COMMANDS };
const { DIALOGS } = dialogs;
const { RESIZES } = splits;

const report = (command) => (e) => console.log(`keys.${command}: ${e}`);

// Key repeat outpaces a resize, and a backlog would keep resizing after the
// key is let go: presses that arrive meanwhile merge into the next one.
const resizes = [];
let resizing = false;

function queueResize(cx, command) {
  const last = resizes.at(-1);
  if (last?.command === command) last.presses++;
  else resizes.push({ command, presses: 1 });
  if (resizing) return;
  resizing = true;
  cx.spawn(async () => {
    while (resizes.length) {
      const { command, presses } = resizes.shift();
      await RESIZES[command](presses).catch(report(command));
    }
    resizing = false;
  });
}

export default class Keys extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (RESIZES[command]) {
          queueResize(cx, command);
        } else if (DIALOGS[command]) {
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
