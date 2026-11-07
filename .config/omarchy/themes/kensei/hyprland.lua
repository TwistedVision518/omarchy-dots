-- Kensei — fluid bladework: soft ink drifts, decisive draws, brass-edged borders.

local active_border_color = {
  colors = { "rgba(d42b2bee)", "rgba(d4a84bcc)", "rgba(7a8f9aaa)" },
  angle = 48,
}
local inactive_border_color = "rgba(3a2824aa)"
local shadow_color = "rgba(050405a0)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
    border_size = 2,
    gaps_in = 10,
    gaps_out = 20,
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    active_opacity = 0.97,
    inactive_opacity = 0.94,
    rounding = 12,
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      xray = false,
      noise = 0.02,
      contrast = 0.88,
      vibrancy = 0.06,
      vibrancy_darkness = 0.65,
      brightness = 0.48,
      popups_ignorealpha = 0.5,
      input_methods_ignorealpha = 0.5,
    },
    shadow = {
      enabled = true,
      range = 18,
      render_power = 3,
      color = shadow_color,
      color_inactive = shadow_color,
      offset = "0 4",
    },
    dim_inactive = true,
    dim_strength = 0.12,
  },

  animations = {
    enabled = true,
  },
})

-- Motion curves: draw the blade, drift like mist, strike clean.
hl.curve("bladeDraw", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.curve("inkDrift", { type = "bezier", points = { { 0.22, 0.82 }, { 0.28, 1.0 } } })
hl.curve("sheathFade", { type = "bezier", points = { { 0.4, 0.0 }, { 0.2, 1.0 } } })
hl.curve("strike", { type = "bezier", points = { { 0.2, 0.0 }, { 0.0, 1.0 } } })
hl.curve("dojoSlide", { type = "bezier", points = { { 0.25, 0.9 }, { 0.32, 1.0 } } })

hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 4.5,
  bezier = "bladeDraw",
})
hl.animation({
  leaf = "windowsIn",
  enabled = true,
  speed = 4.2,
  bezier = "inkDrift",
  style = "popin 12%",
})
hl.animation({
  leaf = "windowsOut",
  enabled = true,
  speed = 3.8,
  bezier = "sheathFade",
  style = "popin 86%",
})
hl.animation({
  leaf = "windowsMove",
  enabled = true,
  speed = 4.8,
  bezier = "bladeDraw",
})
hl.animation({
  leaf = "border",
  enabled = true,
  speed = 5.5,
  bezier = "strike",
})
hl.animation({
  leaf = "borderangle",
  enabled = true,
  speed = 12,
  bezier = "linear",
})
hl.animation({
  leaf = "fade",
  enabled = true,
  speed = 4.5,
  bezier = "sheathFade",
})
hl.animation({
  leaf = "layers",
  enabled = true,
  speed = 4.5,
  bezier = "inkDrift",
  style = "slidefade 8%",
})
hl.animation({
  leaf = "layersIn",
  enabled = true,
  speed = 4.5,
  bezier = "inkDrift",
  style = "slidefade 8%",
})
hl.animation({
  leaf = "layersOut",
  enabled = true,
  speed = 3.8,
  bezier = "sheathFade",
  style = "fade",
})
hl.animation({
  leaf = "workspaces",
  enabled = true,
  speed = 6.5,
  bezier = "dojoSlide",
  style = "slidefade 12%",
})

o.window({ tag = "terminal" }, { opacity = "0.97 0.94" })
