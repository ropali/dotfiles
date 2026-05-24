-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.autoread = true
vim.opt.swapfile = true
vim.opt.backup = false
vim.opt.writebackup = true
vim.opt.backupcopy = "yes"
vim.opt.confirm = true
vim.opt.updatetime = 300

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "checktime",
})
