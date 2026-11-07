-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.envs")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
hl.config({
  decoration = {
    blur = { enabled = true, size = 20, passes = 4, brightness = 0.8, contrast = 0.9, new_optimizations = true, special = false },
    dim_special = 0.0,
  },
})

o.window("org\\.gnome\\.Nautilus", { opacity = "0.65 0.65" })

-- o.window("qemu", { workspace = "5" })
hl.env("XCURSOR_THEME", "Bibata-Material-Lilac-Light")
hl.env("HYPRCURSOR_THEME", "Bibata-Material-Lilac-Light")
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")
