local wezterm = require("wezterm")
local config = wezterm.config_builder()

--- Font settings ---
config.font_size = 12
config.line_height = 1
config.font = wezterm.font("CaskaydiaMono Nerd Font")

--- Colors ---
config.color_scheme = "Dracula (Official)"

--- Appearance ---
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

--- Launch Options ---
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.launch_menu = {
		{
			label = "Windows PowerShell",
			args = { "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe", "-NoLogo" },
		},
	}
end

--- Others ---
--- To use Windows openGL
config.prefer_egl = true

return config
