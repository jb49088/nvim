-- ================================================================================
-- =                                  LAZY.NVIM                                   =
-- ================================================================================

-- Lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        -- import your plugins
        { import = "plugins.ui" },
        { import = "plugins.coding" },
        { import = "plugins.utils" },
        { import = "plugins.lsp_completion" },
    },
    -- ui config
    ui = {
        border = "rounded",
        backdrop = 100,
    },
})
