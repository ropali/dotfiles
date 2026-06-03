-- ==========================================
-- HYPRLAND WINDOW RULES CONFIGURATION
-- ==========================================

-- ------------------------------------------
-- Static Window Rules
-- ------------------------------------------

-- Ignore maximize requests from all apps
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

-- ------------------------------------------
-- Dynamic Window Rules (Events & Callbacks)
-- ------------------------------------------

hl.on("window.open", function(w)
	-- Normalize class to lowercase for case-insensitive matching
	local class = string.lower(w.class or "")

	-- Always open Vivaldi browser in a new workspace silently (follow = false)
	if class == "vivaldi-stable" or class == "vivaldi" or class == "steam" then
		hl.dispatch(hl.dsp.window.move({ workspace = "empty", follow = false }))
	end
end)
