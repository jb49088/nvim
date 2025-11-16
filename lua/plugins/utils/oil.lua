-- ================================================================================
-- =                                   OIL.NVIM                                   =
-- ================================================================================

return {
    "stevearc/oil.nvim",
    -- enabled = false,
    cmd = "Oil",
    opts = function()
        local open_in_right_window = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            local dir = oil.get_current_dir()
            if entry and entry.type == "file" then
                local filepath = dir .. entry.name
                vim.cmd("wincmd l")
                vim.cmd("edit " .. vim.fn.fnameescape(filepath))
            else
                oil.select()
            end
        end

        local open_in_split_right = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            local dir = oil.get_current_dir()
            if entry and entry.type == "file" then
                local filepath = dir .. entry.name
                -- Move to the rightmost non-oil window
                vim.cmd("wincmd l")
                -- Create split to the right of current window
                vim.cmd("rightbelow vsplit")
                vim.cmd("edit " .. vim.fn.fnameescape(filepath))
            else
                oil.select()
            end
        end

        local open_in_split_below = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            local dir = oil.get_current_dir()
            if entry and entry.type == "file" then
                local filepath = dir .. entry.name
                -- Move out of oil first
                vim.cmd("wincmd l")
                -- Create horizontal split below current window
                vim.cmd("rightbelow split")
                vim.cmd("edit " .. vim.fn.fnameescape(filepath))
            else
                oil.select()
            end
        end

        return {
            keymaps = {
                ["<CR>"] = { callback = open_in_right_window },
                ["+"] = { callback = open_in_right_window },
                ["<C-s>"] = { callback = open_in_split_right },
                ["<C-h>"] = { callback = open_in_split_below },
            },
            delete_to_trash = true,
            watch_for_changes = true,
            skip_confirm_for_simple_edits = true,
            view_options = {
                show_hidden = true,
            },
            win_options = {
                winbar = "",
            },
        }
    end,
    keys = {
        {
            "<leader>o",
            function()
                local oil = require("oil")
                local current_buf = vim.api.nvim_get_current_buf()
                local current_file = vim.api.nvim_buf_get_name(current_buf)

                -- Find existing oil window
                local oil_winid = nil
                for _, winid in ipairs(vim.api.nvim_list_wins()) do
                    local bufnr = vim.api.nvim_win_get_buf(winid)
                    local bufname = vim.api.nvim_buf_get_name(bufnr)
                    if bufname:match("^oil://") then
                        oil_winid = winid
                        break
                    end
                end

                if oil_winid then
                    -- Oil window exists, switch back to original buffer, then open oil
                    -- This ensures oil.open() can find the file to position cursor on
                    local original_win = vim.api.nvim_get_current_win()
                    vim.api.nvim_set_current_win(oil_winid)
                    vim.api.nvim_set_current_buf(current_buf)
                    oil.open()
                else
                    -- Create new oil sidebar
                    vim.cmd("vsplit")
                    vim.cmd("wincmd H")
                    vim.cmd("vertical resize 30")
                    vim.wo.winfixwidth = true
                    oil.open()
                end
            end,
            desc = "Oil",
            mode = "n",
        },
    },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}
