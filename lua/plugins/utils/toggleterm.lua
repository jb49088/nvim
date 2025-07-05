return {
    "akinsho/toggleterm.nvim",
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
    end,
}
