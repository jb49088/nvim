-- ================================================================================
-- =                                   OPTIONS                                    =
-- ================================================================================

local opt = vim.opt
local g = vim.g
local cmd = vim.cmd

-- ================================ INTERFACE / UI ================================

g.loaded_matchparen = 1 -- Disable matchparen (using rainbow-delimiters)
g.have_nerd_font = true -- Enable nerd font
opt.number = true -- Show absolute line numbers
opt.relativenumber = true -- Show relative line numbers
opt.mouse = "a" -- Enable mouse in all modes
opt.guicursor:append("c:ver25,a:blinkon0") -- Custom cursor styles
cmd("aunmenu PopUp") -- Disable right click menu
opt.title = true -- Enable window title
opt.laststatus = 3 -- Always show statusline
opt.statuscolumn = "%!v:lua.require'custom.modules.status_column'.get()" -- Custom status column
opt.numberwidth = 4 -- Set line number column width
-- opt.statusline = " " -- Show a blank statusline before heirline loads in
opt.showtabline = 0 -- Disable tabline
opt.cmdheight = 0 -- Hide command line when not in use (prevents noice.nvim layout shift on startup)
opt.signcolumn = "yes" -- Always show sign column (gutter)
opt.termguicolors = true -- Enable true color support
opt.cursorline = true -- Highlight the current line
opt.wrap = false -- Disable line wrapping
opt.breakindent = true -- Indent wrapped lines to match line start
opt.breakindentopt = "list:-1" -- Add padding for lists (if 'wrap' is set)
opt.linebreak = true -- Wrap lines at 'breakat' (if 'wrap' is set)
opt.scrolloff = 10 -- Vertical scroll offset
opt.sidescrolloff = 10 -- Horizontal scroll offset
opt.winborder = "rounded" -- Rounded borders for floating windows
opt.fillchars:append({ eob = " " }) -- Hide "~" at EOF
-- opt.shortmess:append("I") -- Dont show intro message

-- =================================== BEHAVIOR ===================================

opt.swapfile = false -- Disable swap files
opt.undofile = true -- Enable persistent undo
opt.updatetime = 200 -- Faster update time for diagnostics, etc.
opt.timeoutlen = 400 -- Timeout for mapped sequence to complete
opt.splitright = true -- Vertical splits open to the right
opt.splitbelow = true -- Horizontal splits open below
opt.splitkeep = "screen" -- Reduce scroll during window split
opt.confirm = true -- Confirm to save changes when closing
opt.autoread = true -- Enable automatic file reloading (requires checktime triggers to work)
opt.infercase = true -- Infer case in built-in completion
opt.virtualedit = "block" -- Allow going past end of line in blockwise mode
opt.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)

-- ================================== SEARCHING ===================================

opt.ignorecase = true -- Case-insensitive search...
opt.smartcase = true -- ...unless uppercase letters in query
opt.incsearch = true -- Show search matches as you type
opt.hlsearch = true -- Highlight all search matches
opt.inccommand = "split" -- Preview substitute commands live

-- ================================= INDENTATION ==================================

opt.shiftwidth = 4 -- Indent size
opt.tabstop = 4 -- Tab width
opt.expandtab = true -- Convert tabs to spaces
opt.autoindent = true -- Copy indent from current line when starting new one

-- ================================== FORMATTING ==================================

opt.formatoptions = "qnl1j" -- Improve comment editing
opt.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]] -- Regex for numbered list start

-- =================================== SPELLING ===================================

opt.spelloptions = "camel" -- Treat camelCase word parts as separate words

-- ================================== PROVIDERS ===================================

g.loaded_python_provider = 0
g.loaded_python3_provider = 0
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

-- =============================== BUILT-IN PLUGINS ===============================

g.loaded_getscript = 1
g.loaded_getscriptPlugin = 1
g.loaded_vimball = 1
g.loaded_vimballPlugin = 1
g.loaded_2html_plugin = 1
g.loaded_logiPat = 1
g.loaded_rrhelper = 1
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.loaded_netrwSettings = 1
g.loaded_netrwFileHandlers = 1
g.loaded_matchit = 1
g.loaded_matchparen = 1

-- =================================== SECURITY ===================================

opt.modeline = false -- Disable modelines to prevent arbitrary code execution
opt.exrc = false -- Don't auto-load project .vimrc/.nvimrc files

-- ================================== CLIPBOARD ===================================

opt.clipboard = "unnamedplus"

-- https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim
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
