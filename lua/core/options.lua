local opt = vim.opt
local g = vim.g
local cmd = vim.cmd

-- Interface / UI
g.loaded_matchparen = 1 -- Disable matchparen (using rainbow-delimiters)
g.have_nerd_font = true -- Enable nerd font
g.snacks_animate = false -- Disable snacks animations by default
opt.number = true -- Show absolute line numbers
opt.relativenumber = true -- Show relative line numbers
opt.numberwidth = 5 -- Set line number column width
opt.mouse = "a" -- Enable mouse in all modes
opt.guicursor:append("t-c:ver25,a:blinkon0") -- Custom cursor styles
cmd("aunmenu PopUp") -- Disable right click menu
opt.title = true -- Enable window title
opt.titlestring = "%t (%{expand('%:~:.:h')}) - Nvim" -- Custom window title format
-- opt.showmode = false -- Disable mode display in command line
opt.laststatus = 3 -- Always show statusline
opt.statusline = " " -- Show a blank statusline before lualine loads in
opt.showtabline = 0 -- Hide tab line
opt.signcolumn = "yes" -- Always show sign column (gutter)
opt.termguicolors = true -- Enable true color support
opt.cursorline = true -- Highlight the current line...
-- opt.cursorlineopt = "number" -- ...but only highlight the line number
opt.wrap = false -- Disable line wrapping
opt.scrolloff = 999 -- Vertical scroll offset (Keep cursor vertically centered)
opt.sidescrolloff = 10 -- Horizontal scroll offset
-- opt.winborder = "rounded" -- Rounded borders for lsp hover
opt.fillchars:append({ eob = " " }) -- Hide "~" at EOF

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
opt.textwidth = 70 -- Wrap width used by 'gqq' to format comments at 70 chars
-- opt.whichwrap = "h,l,<,>,[,]" -- Allow cursor wrapping with these keys
-- opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions" -- Recommended for auto-session

-- Indentation
opt.shiftwidth = 4 -- Indent size
opt.tabstop = 4 -- Tab width
opt.expandtab = true -- Convert tabs to spaces
opt.autoindent = true -- Copy indent from current line when starting new one
cmd("filetype plugin indent on") -- Enable filetype-specific indentation

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
        cache_enabled = 0,
    }
end
