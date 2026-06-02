local primary = "rgb(b8bb26)"
local surface = "rgb(282828)"
local secondary = "rgb(fabd2f)"
local error_color = "rgb(fb4934)"
local tertiary = "rgb(83a598)"
local surface_lowest = "rgb(2c2b2a)"

hl.config({
	general = {
		col = {
			active_border = primary,
			inactive_border = surface,
		},
	},

	group = {
		col = {
			border_active = secondary,
			border_inactive = surface,
			border_locked_active = error_color,
			border_locked_inactive = surface,
		},
		groupbar = {
			col = {
				active = secondary,
				inactive = surface,
				locked_active = error_color,
				locked_inactive = surface,
			},
		},
	},
})
