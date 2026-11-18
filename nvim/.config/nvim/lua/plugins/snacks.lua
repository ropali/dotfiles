vim.g.snacks_animate = true

return {
  "folke/snacks.nvim",
  init = function()
    -- Snacks caches git status for up to 15 minutes, and only watches open
    -- directories / the git index. That means changes made from Neovim (or
    -- from an external git command) can leave the explorer showing stale
    -- status. Invalidate the cache on save/focus and refresh the explorer if
    -- its own file watcher did not already do it.
    local pending = false
    local function refresh_explorer_git()
      local ok, Snacks = pcall(require, "snacks")
      if not ok then
        return
      end

      local explorers = Snacks.picker.get({ source = "explorer", tab = false })
      if #explorers == 0 then
        return
      end

      local git_ok, git = pcall(require, "snacks.explorer.git")
      if not git_ok then
        return
      end

      for _, picker in ipairs(explorers) do
        if not picker.closed then
          git.refresh(picker:cwd()) -- invalidate the 15-minute status cache
        end
      end

      if pending then
        return
      end
      pending = true
      vim.defer_fn(function()
        pending = false
        local actions = require("snacks.explorer.actions")
        for _, picker in ipairs(explorers) do
          if not picker.closed and git.is_dirty(picker:cwd()) then
            actions.update(picker, { refresh = true })
          end
        end
      end, 400)
    end

    vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
      group = vim.api.nvim_create_augroup("snacks_explorer_git_refresh", { clear = true }),
      callback = refresh_explorer_git,
    })
  end,
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
        explorer = {
          -- Show git status icons/aggregate status next to files and directories.
          git_status = true,
          git_untracked = true,
          -- Also show status for directories that are currently expanded.
          git_status_open = true,
          diagnostics = true,
        },
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