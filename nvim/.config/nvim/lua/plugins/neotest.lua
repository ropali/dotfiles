return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-go",
  },
  opts = {
    adapters = {
      ["rustaceanvim.neotest"] = {},
    },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-go"),
      },
    })
  end,
}
