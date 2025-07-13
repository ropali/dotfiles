-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Run nearest test
vim.keymap.set("n", "<leader>tn", function()
  require("neotest").run.run()
end)

-- Run current file
vim.keymap.set("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end)

-- Toggle summary panel
vim.keymap.set("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end)
