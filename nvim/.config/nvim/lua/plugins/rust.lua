return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rust_analyzer = {
          mason = true,
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer" },
        },
      },
    },
  },
}
