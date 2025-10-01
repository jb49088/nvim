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

-- Black hole registers
map({ "n", "v" }, "x", '"_x', { noremap = true })

-- Buffers
map("n", "<leader>.", "<Cmd>e #<CR>", { desc = "Alternate Buffer" })
map("n", "<leader>ba", function()
    local count = #vim.tbl_filter(function(buf)
        return vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())

    vim.cmd("silent %bd")

    if count > 0 then
        vim.notify(string.format("Closed %d buffer%s", count, count == 1 and "" or "s"))
    end
end, { desc = "Close All Buffers" })
map("n", "<leader>bn", "<Cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<leader>bp", "<Cmd>bprevious<CR>", { desc = "Previous Buffer" })
map("n", "<leader>bC", "<Cmd>bd<CR>", { desc = "Close Buffer and Window" })
map("n", "<leader>bo", function()
    local tab_buffers = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            local buf = vim.api.nvim_win_get_buf(win)
            tab_buffers[buf] = true
        end
    end

    local function is_listable_buffer(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
            return false
        end
        -- Check if buffer is listed (this is the main filter most pickers use)
        if not vim.bo[buf].buflisted then
            return false
        end
        -- Optional: exclude certain buffer types that pickers typically filter out
        local buftype = vim.bo[buf].buftype
        if buftype == "quickfix" or buftype == "help" or buftype == "terminal" then
            return false
        end
        -- Now includes unnamed buffers (removed the name == "" check)
        return true
    end

    local total_listable_buffers = 0
    local deleted = 0
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if is_listable_buffer(buf) then
            total_listable_buffers = total_listable_buffers + 1
            if not tab_buffers[buf] then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
                deleted = deleted + 1
            end
        end
    end

    if deleted > 0 then
        vim.notify(string.format("Closed %d buffer%s", deleted, deleted == 1 and "" or "s"))
    else
        vim.notify("No buffers to close")
    end
end, { desc = "Close Other Buffers" })

-- Windows
-- map("n", "<C-h>", "<C-w><C-h>", { desc = "Go to Left Window" })
-- map("n", "<C-l>", "<C-w><C-l>", { desc = "Go to Right Window" })
-- map("n", "<C-j>", "<C-w><C-j>", { desc = "Go to Lower Window" })
-- map("n", "<C-k>", "<C-w><C-k>", { desc = "Go to Upper Window" })

map("n", "<A-h>", "<C-w>H", { desc = "Move Window to Far Left" })
map("n", "<A-j>", "<C-w>J", { desc = "Move Window to Far Bottom" })
map("n", "<A-k>", "<C-w>K", { desc = "Move Window to Far Top" })
map("n", "<A-l>", "<C-w>L", { desc = "Move Window to Far Right" })

map("n", "<leader>wx", "<C-w>x", { desc = "Swap Window with Next" })
map("n", "<leader>wc", "<C-W>c", { desc = "Close Window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Close Other Windows" })
map("n", "<leader>wn", "<C-w>w", { desc = "Next Window" })
map("n", "<leader>wp", "<C-w>p", { desc = "Previous Window" })
map("n", "<leader>wt", "<C-w>T", { desc = "Break out into a new tab" })
map("n", "<leader>wh", ":new<CR>", { desc = "Horizontal Split" })
map("n", "<leader>wv", ":vnew<CR>", { desc = "Vertical Split" })

-- Tabs
map("n", "<leader><Tab><Tab>", "<Cmd>tabnew<CR>", { desc = "New Tab" })
map("n", "<leader><Tab>n", "<Cmd>tabnext<CR>", { desc = "Next Tab" })
map("n", "<leader><Tab>c", "<Cmd>tabclose<CR>", { desc = "Close Tab" })
map("n", "<leader><Tab>p", "<Cmd>tabprevious<CR>", { desc = "Previous Tab" })
map("n", "<leader><Tab>o", function()
    local tab_count = #vim.api.nvim_list_tabpages()
    if tab_count > 1 then
        vim.cmd("tabonly")
        vim.notify(string.format("Closed %d tab%s", tab_count - 1, tab_count - 1 == 1 and "" or "s"))
    else
        vim.notify("No tabs to close")
    end
end, { desc = "Close Other Tabs" })

-- Commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

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

-- Reset filetype, and restart any filetype-specific tooling (refresh buffer)
map("n", "<leader>br", function()
    local bufnr = vim.api.nvim_get_current_buf()

    -- Clear all diagnostics for this buffer (including nvim-lint)
    vim.diagnostic.reset(nil, bufnr)

    -- Stop all attached LSPs for this buffer (using new API)
    for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        client.stop()
    end

    -- Reload buffer from disk
    vim.cmd("e!")

    -- Re-detect filetype
    vim.cmd("filetype detect")

    -- Re-run FileType autocommands
    vim.cmd("doautocmd FileType")
end, { desc = "Refresh Buffer" })
