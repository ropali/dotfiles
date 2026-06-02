-- ==========================================
-- HYPRLAND ANIMATION CONFIGURATIONS
-- ==========================================

-- ------------------------------------------
-- ACTIVE: [an1] Premium Spring Animations (Mass-spring-damper physics)
-- ------------------------------------------
hl.curve("window_spring", { type = "spring", mass = 1.0, stiffness = 110, dampening = 15 })
hl.curve("workspace_spring", { type = "spring", mass = 1.0, stiffness = 90, dampening = 17 })
hl.curve("fade_spring", { type = "spring", mass = 1.0, stiffness = 100, dampening = 18 })

hl.animation({ leaf = "global", enabled = true, speed = 8, spring = "window_spring" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, spring = "window_spring" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "window_spring" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, spring = "window_spring", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, spring = "window_spring", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4.5, spring = "fade_spring" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4.5, spring = "fade_spring" })
hl.animation({ leaf = "fade", enabled = true, speed = 4.5, spring = "fade_spring" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, spring = "window_spring" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4.5, spring = "window_spring", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 4, spring = "window_spring", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, spring = "workspace_spring", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 6, spring = "workspace_spring", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 6, spring = "workspace_spring", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5, spring = "window_spring" })

-- ------------------------------------------
-- INACTIVE: [an2] Snappy, Sharp & Responsive (High-speed Bezier with overshoot)
-- ------------------------------------------
--[[
hl.curve("snap_window", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1.08 } } })
hl.curve("snap_workspace", { type = "bezier", points = { { 0.3, 0.0 }, { 0.1, 1.05 } } })
hl.curve("sharp_linear", { type = "bezier", points = { { 0.2, 0.2 }, { 0.8, 0.8 } } })

hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "snap_window" })
hl.animation({ leaf = "border", enabled = true, speed = 3.5, bezier = "sharp_linear" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.2, bezier = "snap_window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.8, bezier = "snap_window", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "snap_window", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "sharp_linear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "sharp_linear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "sharp_linear" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.2, bezier = "snap_window" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.8, bezier = "snap_window", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.5, bezier = "snap_window", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "snap_workspace", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "snap_workspace", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "snap_workspace", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "snap_window" })
--]]

-- ------------------------------------------
-- INACTIVE: [an3] Dreamy, Slow & Easing (Gradual ease-in and ease-out transitions)
-- ------------------------------------------
--[[
hl.curve("dreamy_window", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })
hl.curve("dreamy_workspace", { type = "bezier", points = { { 0.42, 0.0 }, { 0.58, 1.0 } } })
hl.curve("dreamy_fade", { type = "bezier", points = { { 0.33, 0.0 }, { 0.67, 1.0 } } })

hl.animation({ leaf = "global", enabled = true, speed = 7, bezier = "dreamy_window" })
hl.animation({ leaf = "border", enabled = true, speed = 6.5, bezier = "dreamy_fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "dreamy_window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5.5, bezier = "dreamy_window", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "dreamy_window", style = "popin 85%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 5.5, bezier = "dreamy_fade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 5.5, bezier = "dreamy_fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 5.5, bezier = "dreamy_fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 6, bezier = "dreamy_window" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 5.5, bezier = "dreamy_window", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "dreamy_window", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "dreamy_workspace", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 7, bezier = "dreamy_workspace", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 7, bezier = "dreamy_workspace", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5.5, bezier = "dreamy_window" })
--]]

-- ------------------------------------------
-- INACTIVE: [an4] Mechanical, Snappy & Elastic (Hardware tactile feedback bounce)
-- ------------------------------------------
--[[
hl.curve("mech_window", { type = "bezier", points = { { 0.175, 0.885 }, { 0.32, 1.275 } } })
hl.curve("mech_workspace", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.1 } } })
hl.curve("mech_fade", { type = "bezier", points = { { 0.25, 0.46 }, { 0.45, 0.94 } } })

hl.animation({ leaf = "global", enabled = true, speed = 5, bezier = "mech_window" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "mech_fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "mech_window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "mech_window", style = "popin 75%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "mech_window", style = "popin 75%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "mech_fade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "mech_fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "mech_fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "mech_window" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "mech_window", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3.5, bezier = "mech_window", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "mech_workspace", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "mech_workspace", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "mech_workspace", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "mech_window" })
--]]

-- ------------------------------------------
-- INACTIVE: [an5] Fluid Gel & Water Droplet (Dynamic elastic springs)
-- ------------------------------------------
--[[
hl.curve("fluid_window", { type = "spring", mass = 0.8, stiffness = 160, dampening = 12 })
hl.curve("fluid_workspace", { type = "spring", mass = 0.7, stiffness = 140, dampening = 11 })
hl.curve("fluid_fade", { type = "spring", mass = 1.0, stiffness = 120, dampening = 14 })

hl.animation({ leaf = "global", enabled = true, speed = 6, spring = "fluid_window" })
hl.animation({ leaf = "border", enabled = true, speed = 5, spring = "fluid_fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "fluid_window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, spring = "fluid_window", style = "popin 75%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, spring = "fluid_window", style = "popin 75%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, spring = "fluid_fade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, spring = "fluid_fade" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, spring = "fluid_fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, spring = "fluid_window" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, spring = "fluid_window", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, spring = "fluid_window", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5.5, spring = "fluid_workspace", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5.5, spring = "fluid_workspace", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, spring = "fluid_workspace", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, spring = "fluid_window" })
--]]
