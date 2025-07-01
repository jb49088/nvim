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
        vim.keymap.set("n", "<leader>r", function()
            if vim.bo.buftype ~= "" then
                return
            end

            vim.cmd("write")
            local filename = vim.api.nvim_buf_get_name(0)
            if filename ~= "" then
                vim.cmd("ToggleTerm direction=float count=1")
                vim.defer_fn(function()
                    vim.cmd("TermExec cmd='python3 " .. filename .. "' count=1")
                end, 20)
            end
        end, { desc = "Run" })
    end,
}
