local opt = vim.opt
local g = vim.g
local cmd = vim.cmd

-- Interface / UI
g.loaded_matchparen = 1 -- Disable matchparen (using rainbow-delimiters)
g.have_nerd_font = true -- Enable nerd font
opt.number = true -- Show absolute line numbers
opt.relativenumber = true -- Show relative line numbers
opt.numberwidth = 5 -- Set line number column width
opt.mouse = "a" -- Enable mouse in all modes
opt.guicursor:append("t-c:ver25,a:blinkon0") -- Custom cursor styles
cmd("aunmenu PopUp") -- Disable right click menu
opt.title = true -- Enable window title
opt.titlestring = "%t (%{expand('%:~:.:h')}) - Nvim" -- Custom window title format
opt.laststatus = 3 -- Always show statusline
opt.statuscolumn = "%!v:lua.require'custom.modules.status_column'.get()" -- Custom status column
opt.statusline = " " -- Show a blank statusline before heirline loads in
opt.showtabline = 0 -- Disable tabline
opt.signcolumn = "yes" -- Always show sign column (gutter)
opt.termguicolors = true -- Enable true color support
opt.cursorline = true -- Highlight the current line...
opt.wrap = false -- Disable line wrapping
opt.scrolloff = 10 -- Vertical scroll offset
opt.sidescrolloff = 10 -- Horizontal scroll offset
-- opt.winborder = "rounded" -- Rounded borders for floating windows (off until https://github.com/folke/which-key.nvim/pull/964)
opt.fillchars:append({ eob = " " }) -- Hide "~" at EOF
-- cmd("syntax on")

-- Behavior
opt.swapfile = false -- Disable swap files
opt.undofile = true -- Enable persistent undo
opt.ignorecase = true -- Case-insensitive search...
opt.smartcase = true -- ...unless uppercase letters in query
opt.inccommand = "split" -- Preview substitute commands live
opt.updatetime = 250 -- Faster update time for diagnostics, etc.
opt.timeoutlen = 300 -- Timeout for mapped sequence to complete
opt.splitright = true -- Vertical splits open to the right
opt.splitbelow = true -- Horizontal splits open below
opt.confirm = true -- Confirm to save changes when closing
-- opt.whichwrap = "h,l,<,>,[,]" -- Allow cursor wrapping with these keys
-- opt.textwidth = 60 -- Set text width to 60 characters for wrapping operations
-- cmd("set formatoptions-=t") -- Disable automatic text wrapping while typing
-- cmd("set formatoptions+=l") -- Don't break existing long lines when entering insert mode

-- Indentation
opt.shiftwidth = 4 -- Indent size
opt.tabstop = 4 -- Tab width
opt.expandtab = true -- Convert tabs to spaces
opt.autoindent = true -- Copy indent from current line when starting new one

-- Providers
g.loaded_python3_provider = 0
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- Clipboard (from https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim)
opt.clipboard = "unnamedplus"

if vim.fn.has("wsl") == 1 then
    local win32yank = "win32yank.exe"
    if vim.fn.getftype(vim.fn.exepath(win32yank)) == "link" then
        win32yank = vim.fn.resolve(vim.fn.exepath(win32yank))
    end

    vim.g.clipboard = {
        name = "win32yank",
        copy = {
            ["+"] = { win32yank, "-i", "--crlf" },
            ["*"] = { win32yank, "-i", "--crlf" },
        },
        paste = {
            ["+"] = { win32yank, "-o", "--lf" },
            ["*"] = { win32yank, "-o", "--lf" },
        },
        cache_enabled = 1, -- cache fixes del lag
    }
end
