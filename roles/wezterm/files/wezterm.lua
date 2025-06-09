local wezterm = require("wezterm")
local config = wezterm.config_builder()

--- Font settings ---
config.font_size = 12
config.line_height = 1
config.font = wezterm.font("CaskaydiaMono Nerd Font")

--- Colors ---
config.term = "xterm-256color"
config.color_scheme = "Dracula (Official)"

--- Appearance ---
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

--- Launch Options ---
-- Set default domain to WSL Arch, fallback to Ubuntu
local launch_menu = {}

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
	-- Windows-specific launch options
	table.insert(launch_menu, {
		label = 'PowerShell',
		domain = { DomainName = "local" },
		args = { 'powershell.exe', '-NoLogo' },
	})

	table.insert(launch_menu, {
		label = 'PowerShell Admin',
		domain = { DomainName = "local" },
		args = { 'powershell.exe', '-NoLogo', '-Command', 'Start-Process powershell -Verb RunAs' },
	})

	-- Set default domain to WSL
	config.default_domain = 'WSL:Arch'

	-- Define WSL domains with fallback
	config.wsl_domains = {
		{
			name = 'WSL:Arch',
			distribution = 'Arch',
			default_cwd = '~',
		},
		{
			name = 'WSL:Ubuntu',
			distribution = 'Ubuntu',
			default_cwd = '~',
		},
	}
end

config.launch_menu = launch_menu

--- Key Bindings ---
config.keys = config.keys or {}

table.insert(config.keys, {
	key = "p",
	mods = "CTRL|SHIFT",
	action = wezterm.action.ShowLauncher,
})

--- Others ---
--- To use Windows openGL
config.prefer_egl = true

return config
