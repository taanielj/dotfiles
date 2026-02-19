local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Catppuccin Macchiato bg/fg only, full color_scheme pastels out ANSI colors for daltonism
config.colors = {
	foreground = "#cad3f5",
	background = "#24273a",
}
config.font = wezterm.font("JetBrains Mono NL", { weight = "Regular" })
config.font_rules = {
	{ intensity = "Bold", font = wezterm.font("JetBrains Mono NL", { weight = "ExtraBold" }) },
	{ italic = true, font = wezterm.font("JetBrains Mono NL", { weight = "Medium", italic = true }) },
	{ intensity = "Bold", italic = true, font = wezterm.font("JetBrains Mono NL", { weight = "ExtraBold", italic = true }) },
}
config.font_size = 18.0
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.window_decorations = "RESIZE | MACOS_FORCE_SQUARE_CORNERS"
config.window_background_opacity = 0.8
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.enable_tab_bar = false

-- macOS-specific settings
if wezterm.target_triple:find("darwin") then
	config.send_composed_key_when_left_alt_is_pressed = false
	config.send_composed_key_when_right_alt_is_pressed = true
	config.macos_window_background_blur = 25

	-- Helper: CMD+key sends CTRL+key
	local function cmd_to_ctrl(key)
		return { key = key, mods = "CMD", action = act.SendKey({ key = key, mods = "CTRL" }) }
	end

	local function cmd_shift_to_ctrl_shift(key)
		return { key = key, mods = "CMD|SHIFT", action = act.SendKey({ key = key, mods = "CTRL|SHIFT" }) }
	end

	config.keys = {
		-- Cmd+letter → Ctrl+letter (Karabiner swaps physical Ctrl↔Cmd)
		cmd_to_ctrl("a"),
		cmd_to_ctrl("b"),
		-- copy if selection exists, otherwise send ctrl+c (matches kitty copy_and_clear_or_interrupt)
		{
			key = "c",
			mods = "CMD",
			action = wezterm.action_callback(function(window, pane)
				local sel = window:get_selection_text_for_pane(pane)
				if sel and sel ~= "" then
					window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
					window:perform_action(act.ClearSelection, pane)
				else
					window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
				end
			end),
		},
		cmd_to_ctrl("d"),
		cmd_to_ctrl("e"),
		cmd_to_ctrl("f"),
		cmd_to_ctrl("g"),
		cmd_to_ctrl("h"),
		cmd_to_ctrl("i"),
		cmd_to_ctrl("j"),
		cmd_to_ctrl("k"),
		cmd_to_ctrl("l"),
		-- cmd+m = minimize (macOS default, keep it)
		cmd_to_ctrl("n"),
		cmd_to_ctrl("o"),
		cmd_to_ctrl("p"),
		-- cmd+q = quit (macOS default, keep it)
		cmd_to_ctrl("r"),
		cmd_to_ctrl("s"),
		cmd_to_ctrl("t"),
		cmd_to_ctrl("u"),
		cmd_to_ctrl("v"),
		cmd_to_ctrl("w"),
		cmd_to_ctrl("x"),
		cmd_to_ctrl("y"),
		cmd_to_ctrl("z"),

		-- Cmd+number → Ctrl+number
		cmd_to_ctrl("1"),
		cmd_to_ctrl("2"),
		cmd_to_ctrl("3"),
		cmd_to_ctrl("4"),
		cmd_to_ctrl("5"),
		cmd_to_ctrl("6"),
		cmd_to_ctrl("7"),
		cmd_to_ctrl("8"),
		cmd_to_ctrl("9"),
		cmd_to_ctrl("0"),

		-- Cmd+Shift+letter → Ctrl+Shift+letter
		{ key = "f", mods = "CMD|SHIFT", action = act.SendKey({ key = "f", mods = "CTRL|SHIFT" }) },
		cmd_shift_to_ctrl_shift("h"),
		cmd_shift_to_ctrl_shift("j"),
		cmd_shift_to_ctrl_shift("k"),
		cmd_shift_to_ctrl_shift("l"),

		-- Cmd+arrows → Ctrl+arrows
		cmd_to_ctrl("LeftArrow"),
		cmd_to_ctrl("RightArrow"),
		cmd_to_ctrl("UpArrow"),
		cmd_to_ctrl("DownArrow"),
		cmd_shift_to_ctrl_shift("LeftArrow"),
		cmd_shift_to_ctrl_shift("RightArrow"),
		cmd_shift_to_ctrl_shift("UpArrow"),
		cmd_shift_to_ctrl_shift("DownArrow"),

		-- Special sends
		{ key = "Backspace", mods = "CMD", action = act.SendString("\x17") }, -- ctrl+w
		{ key = "Delete", mods = "CMD", action = act.SendKey({ key = "Delete", mods = "CTRL" }) },
		{ key = " ", mods = "CMD", action = act.SendString("\x00") }, -- ctrl+space
		{ key = "'", mods = "CMD", action = act.SendKey({ key = "'", mods = "CTRL" }) },

		-- macOS actions (keep on Cmd)
		{ key = "n", mods = "CMD|SHIFT", action = act.SpawnCommandInNewWindow({ cwd = wezterm.home_dir }) },
		{ key = "w", mods = "CMD|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "v", mods = "CMD|SHIFT", action = act.PasteFrom("Clipboard") },
		{ key = "`", mods = "CMD", action = act.ActivateWindowRelative(1) },
		{ key = "`", mods = "ALT", action = act.ActivateWindowRelative(1) },

		-- Opacity toggle (matches kitty cmd+alt+shift+o)
		{
			key = "o",
			mods = "CMD|ALT|SHIFT",
			action = wezterm.action_callback(function(window, _)
				local overrides = window:get_config_overrides() or {}
				if overrides.window_background_opacity == 1.0 then
					overrides.window_background_opacity = 0.8
				else
					overrides.window_background_opacity = 1.0
				end
				window:set_config_overrides(overrides)
			end),
		},
		-- Opacity adjust (matches kitty cmd+option+control+Up/Down)
		{
			key = "UpArrow",
			mods = "CMD|ALT|CTRL",
			action = wezterm.action_callback(function(window, _)
				local overrides = window:get_config_overrides() or {}
				local opacity = overrides.window_background_opacity or config.window_background_opacity
				overrides.window_background_opacity = math.min(1.0, opacity + 0.1)
				window:set_config_overrides(overrides)
			end),
		},
		{
			key = "DownArrow",
			mods = "CMD|ALT|CTRL",
			action = wezterm.action_callback(function(window, _)
				local overrides = window:get_config_overrides() or {}
				local opacity = overrides.window_background_opacity or config.window_background_opacity
				overrides.window_background_opacity = math.max(0.0, opacity - 0.1)
				window:set_config_overrides(overrides)
			end),
		},

		-- Disable defaults that conflict
		{ key = "Enter", mods = "CMD", action = act.DisableDefaultAssignment },
		{ key = "Tab", mods = "CTRL", action = act.DisableDefaultAssignment },
		{ key = "Tab", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
	}
end

return config
