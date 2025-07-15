return {
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        goimport = "gopls", -- use gopls for imports
        gofmt = "gofumpt",
        max_line_len = 120,
        lsp_cfg = false, -- use your existing lspconfig setup
        lsp_keymaps = false, -- let LazyVim handle keymaps
        lsp_on_attach = nil, -- use default on_attach
        dap_debug = true,
        dap_debug_gui = true,
        test_runner = "go", -- can be "go" or "richgo"
        run_in_floaterm = true,
      })
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
  },

  {
    "leoluz/nvim-dap-go",
    config = function()
      require("dap-go").setup()
    end,
    ft = "go",
  },
}
