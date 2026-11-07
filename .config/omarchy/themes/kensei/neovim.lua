return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#0c0a0b",
        dark_bg = "#080708",
        darker_bg = "#050405",
        lighter_bg = "#1a1416",

        fg = "#e8dcc8",
        dark_fg = "#6b5e58",
        light_fg = "#c4b5a0",
        bright_fg = "#f5efe4",
        muted = "#6b5e58",

        red = "#d42b2b",
        yellow = "#d4a84b",
        orange = "#c4713b",
        green = "#5a7a62",
        cyan = "#7a8f9a",
        blue = "#4a5e78",
        magenta = "#9a4a5c",
        brown = "#5c3a28",

        bright_red = "#f05555",
        bright_yellow = "#e8c878",
        bright_green = "#7a9a82",
        bright_cyan = "#a0b4be",
        bright_blue = "#6a82a0",
        bright_magenta = "#c07088",

        accent = "#d42b2b",
        cursor = "#f5efe4",
        foreground = "#e8dcc8",
        background = "#0c0a0b",
        selection = "#2a1218",
        selection_foreground = "#f5efe4",
        selection_background = "#2a1218",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
