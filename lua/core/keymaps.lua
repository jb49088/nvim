local map = vim.keymap.set

-- Global leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic keymaps
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })
map("n", "<leader>l", "<Cmd>Lazy<CR>", { desc = "Lazy" })
map("n", "<leader>cm", "<Cmd>Mason<CR>", { desc = "Mason" })
map("n", "<leader>K", "<Cmd>norm! K<CR>", { desc = "Keywordprg" })

-- Buffers
map("n", "<leader>.", "<Cmd>e #<CR>", { desc = "Switch to Alternate Buffer" })
map("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous Buffer" })
map("n", "<leader>bC", "<Cmd>bd<CR>", { desc = "Close Buffer and Window" })

-- Windows
map("n", "<C-h>", "<C-w><C-h>", { desc = "Go to Left Window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Go to Right Window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Go to Lower Window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Go to Upper Window" })

map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to Left Window from Terminal" })
map("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to Right Window from Terminal" })
map("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to Lower Window from Terminal" })
map("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to Upper Window from Terminal" })

map("n", "<leader>wx", "<C-w>x", { desc = "Swap Window with Next" })
map("n", "<leader>wc", "<C-W>c", { desc = "Close Window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Close Other Windows" })
map("n", "<leader>wn", "<C-w>w", { desc = "Next Window" })
map("n", "<leader>wp", "<C-w>p", { desc = "Previous Window" })
map("n", "<leader>wt", "<C-w>T", { desc = "Break out into a new tab" })
map("n", "<leader>wh", ":split<CR>", { desc = "Horizontal Split" })
map("n", "<leader>wv", ":vsplit<CR>", { desc = "Vertical Split" })

-- Tabs
map("n", "<leader>to", "<Cmd>tabonly<CR>", { desc = "Close Other Tabs" })
map("n", "<leader>tt", "<Cmd>tabnew<CR>", { desc = "New Tab" })
map("n", "<leader>tn", "<Cmd>tabnext<CR>", { desc = "Next Tab" })
map("n", "<leader>tc", "<Cmd>tabclose<CR>", { desc = "Close Tab" })
map("n", "<leader>tp", "<Cmd>tabprevious<CR>", { desc = "Previous Tab" })

-- Terminal
map("n", "<leader>Tf", "<Cmd>terminal<CR>", { desc = "Fullscreen Terminal" })
map("n", "<leader>Tv", "<Cmd>vsplit | terminal<CR>", { desc = "Vertical Terminal" })
map("n", "<leader>Th", "<Cmd>split | terminal<CR>", { desc = "Horizontal Terminal" })

-- Consistent and flicker-free scrolling
map("n", "<C-d>", function()
    local original_cursorline = vim.o.cursorline
    vim.o.cursorline = false
    vim.cmd("normal! " .. vim.o.scroll .. "j")
    vim.o.cursorline = original_cursorline
end, { noremap = true, silent = true })

map("n", "<C-u>", function()
    local original_cursorline = vim.o.cursorline
    vim.o.cursorline = false
    vim.cmd("normal! " .. vim.o.scroll .. "k")
    vim.o.cursorline = original_cursorline
end, { noremap = true, silent = true })

-- Quickfix list
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

map("n", "<leader>xq", function()
    local success, err = pcall(function()
        if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
            vim.cmd.cclose()
        else
            vim.cmd.copen()
        end
    end)
    if not success and err then
        vim.notify(err, vim.log.levels.ERROR)
    end
end, { desc = "Quickfix list" })

-- Location list
map("n", "<leader>xl", function()
    local success, err = pcall(function()
        if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
            vim.cmd.lclose()
        else
            vim.cmd.lopen()
        end
    end)
    if not success and err then
        vim.notify(err, vim.log.levels.ERROR)
    end
end, { desc = "Location List" })

-- Clear search, diff update and redraw (refresh ui)
map("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", { desc = "Refresh UI" })

-- Inspect position and syntax tree
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
    vim.treesitter.inspect_tree()
    vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })
