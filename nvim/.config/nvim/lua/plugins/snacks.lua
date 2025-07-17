vim.g.snacks_animate = true

return {
  "folke/snacks.nvim",
  opts = {
    -- need notifier for disabling "No notifications available"
    notifier = { enabled = true },

    image = { enabled = true },

    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
      },
    },

    picker = {
      sources = {
        projects = {},
        files = {
          hidden = true,
          ignored = true,
        },
      },
      -- show hidden files like .env
      hidden = true,
      -- show files ignored by git like node_modules
      ignored = true,

      exclude = {
        ".git/",
      },
    },

    dashboard = {
      preset = {},
    },
  },
}