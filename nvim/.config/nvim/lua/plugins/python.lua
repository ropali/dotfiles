-- ~/.config/nvim/lua/plugins/python.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            pyright = {
              disableOrganizeImports = false,
              analysis = {
                useLibraryCodeForTypes = true,
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                typeCheckingMode = "off",
              },
            },
          },
        },
        ruff_lsp = {
          init_options = {
            settings = {
              args = { "--select=ALL" },
            },
          },
        },
      },
      setup = {
        ruff_lsp = function()
          -- You can add custom on_attach for ruff if needed
        end,
      },
    },
  },

  -- Optional: Additional Python tools
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      name = { "venv", ".venv", "env" },
    },
  },
}
