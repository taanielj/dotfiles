// Herdr's workspace-status bar, plus the herdr tab bar's right side: network
// speed, CPU and memory, weather and the time, from herdr/bin's scripts.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, agents, theme, run, window, keys, exec, home, settings } from "herdr";

// Each script with its arguments and how often it reruns; the weather script
// caches for 15 minutes itself.
const SCRIPTS = [
  ["herdr-netspeed", ["app"], 1000],
  ["herdr-sysmon", [], 1000],
  ["herdr-weather", [], 900000],
];

export default class WorkspaceStatus extends View {
  init(_props, cx) {
    this.out = {};
    this.time = "";
    for (const [script, args, ms] of SCRIPTS) {
      const refresh = (cx) => cx.spawn(async (cx) => {
        const r = await exec(`${home()}/.local/bin/${script}`, args, { timeout: 10000 });
        this.out[script] = r.code === 0 ? r.stdout.trim() : "";
        cx.notify();
      });
      refresh(cx);
      cx.timer.every(ms, refresh);
    }
    const tick = (cx) => {
      this.time = new Date().toTimeString().slice(0, 5);
      cx.notify();
    };
    tick(cx);
    cx.timer.every(1000, tick);
  }

  // The palette key as actually bound, not a hardcoded one; without a
  // binding the hint stays useful ("commands") instead of lying.
  hint(t) {
    const mac = window()?.platform === "macos";
    const mod = { cmd: mac ? "⌘" : "Ctrl+", ctrl: mac ? "⌃" : "Ctrl+", shift: mac ? "⇧" : "Shift+", alt: mac ? "⌥" : "Alt+", option: mac ? "⌥" : "Alt+" };
    const b = keys().find((k) => k.section === "global" && k.action === "app.palette");
    const parts = b && b.keys.endsWith("--") ? [...b.keys.slice(0, -2).split("-"), "-"] : b?.keys.split("-");
    const key = parts && parts.map((p) => mod[p.toLowerCase()] ?? p.toUpperCase()).join("");
    return key ? `${key}  commands` : "commands";
  }

  render() {
    const t = theme();
    const space = spaces().find(s => s.active);
    const list = agents();
    const needs = list.filter(a => a.status === "blocked").length;
    const label = (icon, text) => h_flex().gap(6).items_center().child(svg(`mods/workspace-chrome/${icon}.svg`).size(13)).child(text);
    return h_flex().size_full().px(14).gap(16).items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8).text_color(t.muted)
      .child(label(space?.machine ? "server" : "monitor", space?.machine ?? "This computer"))
      .when(Boolean(space?.branch), el => el.child(label("branch", space.branch)))
      .child(h_flex().gap(6).items_center().child(div().size(6).rounded(3).bg(t.dim)).child(`${list.length} agents`)
        .when(needs > 0, el => el.child(div().text_color(t.blocked).child(`· ${needs} needs you`))))
      .child(div().flex_1())
      .child(h_flex().gap(8).items_center().font_family(settings().font_family ?? "JetBrains Mono")
        .children([...SCRIPTS.map(([script]) => this.out[script]), this.time].filter(Boolean).flatMap((text, i) =>
          i ? [div().text_color(t.dim).child("·"), div().child(text)] : [div().child(text)])))
      .child(div().id("palette").text_color(t.dim).on_click(() => run("app.palette")).child(this.hint(t)));
  }
}
