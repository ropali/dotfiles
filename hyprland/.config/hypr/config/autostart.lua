-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("noctalia")
	hl.exec_cmd("xhost +SI:localuser:root")

	-- User startup apps: browser on workspace 1, terminal on workspace 2.
	-- "silent" keeps focus on the current workspace while they launch.
	hl.exec_cmd(BROWSER, { workspace = "1 silent" })
	hl.exec_cmd(TERMINAL, { workspace = "2 silent" })
end)
