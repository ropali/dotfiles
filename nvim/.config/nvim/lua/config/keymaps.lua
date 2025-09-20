-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Run nearest test
vim.keymap.set("n", "<leader>tn", function()
    require("neotest").run.run()
    require("neotest").summary.open()
end, { desc = "Run nearest test" })

-- Run current file
vim.keymap.set("n", "<leader>tf", function()
    require("neotest").run.run(vim.fn.expand("%"))
    require("neotest").summary.open()
end, { desc = "Run current file tests" })

-- Toggle summary panel
vim.keymap.set("n", "<leader>ts", function()
    require("neotest").summary.toggle()
end, { desc = "Toggle test summary" })

-- Run all tests
vim.keymap.set("n", "<leader>ta", function()
    require("neotest").run.run("tests")
    require("neotest").summary.open()
end, { desc = "Run all tests" })

vim.keymap.set({ "n", "v" }, "<leader>fm", function()
    require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format file or range (in visual mode)" })
