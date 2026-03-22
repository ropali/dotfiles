-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local uv = vim.uv or vim.loop
local py_env_mtime_by_venv = {}
local py_buf_venv = {}

local python_clients = {
  pyright = true,
  basedpyright = true,
  ty = true,
  ruff = true,
  ruff_lsp = true,
}

local function python_project_venv(bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local start_dir = bufname ~= "" and vim.fs.dirname(bufname) or uv.cwd()
  local markers = { "pyproject.toml", "uv.lock", "setup.py", "requirements.txt", ".git" }
  local root_marker = vim.fs.find(markers, { path = start_dir, upward = true })[1]
  local root = root_marker and vim.fs.dirname(root_marker) or nil

  if root then
    for _, name in ipairs({ ".venv", "venv", "env" }) do
      local candidate = root .. "/" .. name
      local stat = uv.fs_stat(candidate)
      if stat and stat.type == "directory" then
        return candidate
      end
    end
  end

  local active_venv = vim.env.VIRTUAL_ENV
  if active_venv and active_venv ~= "" then
    return active_venv
  end
end

local function python_env_mtime(venv)
  local paths = { venv, venv .. "/pyvenv.cfg", venv .. "/Lib/site-packages" }
  vim.list_extend(paths, vim.fn.glob(venv .. "/lib/python*/site-packages", true, true))

  local latest = 0
  for _, path in ipairs(paths) do
    local stat = uv.fs_stat(path)
    if stat and stat.mtime and stat.mtime.sec and stat.mtime.sec > latest then
      latest = stat.mtime.sec
    end
  end
  return latest
end

local function restart_python_lsp(bufnr, message)
  local stopped = false
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if python_clients[client.name] then
      vim.lsp.stop_client(client.id, true)
      stopped = true
    end
  end

  if stopped then
    vim.defer_fn(function()
      vim.cmd("LspStart")
      if message then
        vim.notify(message, vim.log.levels.INFO)
      end
    end, 100)
  end
end

vim.api.nvim_create_user_command("PyRefreshLsp", function()
  restart_python_lsp(vim.api.nvim_get_current_buf(), "Python LSP refreshed")
end, { desc = "Restart Python LSP clients in current buffer" })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("python_env_auto_refresh", { clear = true }),
  pattern = "*.py",
  callback = function(args)
    local venv = python_project_venv(args.buf)
    if not venv then
      return
    end

    local previous_venv = py_buf_venv[args.buf]
    py_buf_venv[args.buf] = venv
    if previous_venv and previous_venv ~= venv then
      restart_python_lsp(args.buf, "Detected Python venv switch; refreshed LSP")
      return
    end

    local current_mtime = python_env_mtime(venv)
    if current_mtime == 0 then
      return
    end

    local previous_mtime = py_env_mtime_by_venv[venv]
    py_env_mtime_by_venv[venv] = current_mtime
    if previous_mtime and current_mtime > previous_mtime then
      restart_python_lsp(args.buf, "Detected Python dependency change; refreshed LSP")
    end
  end,
})
