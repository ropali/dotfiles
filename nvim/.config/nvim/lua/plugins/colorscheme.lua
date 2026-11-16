return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- Apply the Noctalia-generated base16 theme.
      -- Noctalia renders lua/matugen-template.lua -> lua/matugen.lua
      -- and sends SIGUSR1 on palette changes (see the signal handler there).
      colorscheme = function()
        local ok, matugen = pcall(require, "matugen")
        if ok then
          matugen.setup()
        end
      end,
    },
  },
}
