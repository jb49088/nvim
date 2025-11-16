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
                vim.cmd("vsplit")
                vim.cmd("wincmd H")
                vim.cmd("vertical resize 30")
                vim.wo.winfixwidth = true
                require("oil").open()
            end,
            desc = "Oil",
            mode = "n",
        },
    },
    config = function(_, opts)
        require("oil").setup(opts)
    end,
}
