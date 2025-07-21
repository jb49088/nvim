return {
    "akinsho/toggleterm.nvim",
    enabled = false,
    version = "*",
    config = function()
        require("toggleterm").setup({
            open_mapping = [[<c-\>]],
            shade_terminals = false,
            direction = "float",
            persist_mode = false,
            shell = vim.o.shell,
            float_opts = { border = "curved" },
            highlights = { FloatBorder = { link = "FloatBorder" } },
        })
        vim.keymap.set("n", "<leader>TF", "<cmd>ToggleTerm direction=float<cr>", { desc = "Floating Terminal" })
        local interpreters = {
            py = "python3",
            lua = "lua",
        }
        vim.keymap.set("n", "<leader>r", function()
            if vim.bo.buftype ~= "" then
                return
            end
            vim.cmd("write")
            local filename = vim.api.nvim_buf_get_name(0)
            if filename ~= "" then
                local extension = vim.fn.fnamemodify(filename, ":e")
                local interpreter = interpreters[extension]
                if not interpreter then
                    print("Unsupported file type: " .. extension)
                    return
                end
                local cmd = interpreter .. " " .. filename
                vim.cmd("ToggleTerm direction=float count=1")
                vim.defer_fn(function()
                    vim.cmd("TermExec cmd='" .. cmd .. "' count=1")
                end, 10)
            end
        end, { desc = "Run" })

        -- Visual mode: run selection in REPL
        vim.keymap.set({ "v", "x" }, "<leader>r", function()
            if vim.bo.buftype ~= "" then
                return
            end

            -- Get visual selection using mode-aware approach
            local mode = vim.fn.mode()
            local start_line, start_col, end_line, end_col

            if mode == "v" or mode == "V" then
                -- Get current visual selection
                local start_pos = vim.fn.getpos(".")
                local end_pos = vim.fn.getpos("v")

                start_line = math.min(start_pos[2], end_pos[2])
                end_line = math.max(start_pos[2], end_pos[2])
                start_col = math.min(start_pos[3], end_pos[3])
                end_col = math.max(start_pos[3], end_pos[3])
            else
                return
            end

            local lines = vim.fn.getline(start_line, end_line)

            -- Ensure lines is always a table
            if type(lines) == "string" then
                lines = { lines }
            end

            if #lines == 0 then
                return
            end

            -- Handle partial line selections only in character visual mode
            if mode == "v" then
                if #lines == 1 then
                    lines[1] = string.sub(lines[1], start_col, end_col)
                else
                    lines[1] = string.sub(lines[1], start_col)
                    lines[#lines] = string.sub(lines[#lines], 1, end_col)
                end
            end
            -- In visual line mode (V), use entire lines as-is

            local selected_text = table.concat(lines, "\n")
            local filename = vim.api.nvim_buf_get_name(0)
            local extension = vim.fn.fnamemodify(filename, ":e")
            local interpreter = interpreters[extension]

            if not interpreter then
                print("Unsupported file type: " .. extension)
                return
            end

            vim.cmd("ToggleTerm direction=float count=2")
            vim.defer_fn(function()
                vim.cmd("TermExec cmd='" .. interpreter .. "' count=2")
                vim.defer_fn(function()
                    local escaped_text = selected_text:gsub("'", "'\"'\"'")
                    vim.cmd("TermExec cmd='" .. escaped_text .. "' count=2")
                end, 50)
            end, 10)
        end, { desc = "Run" })
    end,
}
