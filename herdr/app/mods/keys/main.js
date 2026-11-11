// Key commands the app has no single command for, bound in keys.json as
// keys.<command>. The layout docks this mod in a zero-width block, because herdr
// delivers commands only to a mod that is shown.
import { View, div } from "gpui-kit";
import { appHome, nextCommand } from "herdr";
import * as dialogs from "./dialogs.js";
import * as layouts from "./layouts.js";
import * as splits from "./splits.js";
import { mark, timed } from "./timing.js";
import * as zen from "./zen.js";

const COMMANDS = { ...dialogs.COMMANDS, ...layouts.COMMANDS, ...splits.COMMANDS, ...zen.COMMANDS };
const { DIALOGS } = dialogs;
const { RESIZES } = splits;

const report = (command) => (e) => console.log(`keys.${command}: ${e}`);

// Key repeat outpaces a resize. Presses that arrive during a resize merge into
// one queued resize, to stop resizing once the key is released.
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
    mark(`init ${appHome()}`);
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        mark(`recv ${command}`);
        if (RESIZES[command]) {
          queueResize(cx, command);
        } else if (DIALOGS[command]) {
          // A dialog command runs as its own task, to keep other keys working while the dialog is open
          cx.spawn((cx) => DIALOGS[command](cx).catch(report(command)));
        } else if (COMMANDS[command]) {
          await timed(`done ${command}`, () => COMMANDS[command](cx).catch(report(command)));
        }
      }
    });
  }

  render() {
    return div();
  }
}
