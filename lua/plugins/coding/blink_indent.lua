return {
    "saghen/blink.indent",
    enabled = true,
    config = function()
        require("blink.indent").setup({
            static = {
                char = "│",
            },
            scope = {
                char = "│",
                highlights = { "BlinkIndentScope" },
            },
        })

        -- Mode to color mapping
        local modes = {
            n = "ModeColorNormal",
            nt = "ModeColorNormal",
            i = "ModeColorInsert",
            v = "ModeColorVisual",
            V = "ModeColorVisual",
            ["\22"] = "ModeColorVisual",
            s = "ModeColorVisual",
            S = "ModeColorVisual",
            ["\19"] = "ModeColorVisual",
            c = "ModeColorCommand",
            t = "ModeColorTerminal",
            R = "ModeColorReplace",
            Rc = "ModeColorReplace",
            Rx = "ModeColorReplace",
            Rv = "ModeColorReplace",
            Rvc = "ModeColorReplace",
            Rvx = "ModeColorReplace",
            r = "ModeColorReplace",
        }

        -- Function to update BlinkIndentScope color based on mode
        local function update_indent_color(mode)
            if modes[mode] then
                vim.api.nvim_set_hl(0, "BlinkIndentScope", { link = modes[mode] })
                if mode == "c" then
                    vim.cmd.redraw()
                end
            end
        end

        -- Set initial color
        update_indent_color(vim.api.nvim_get_mode().mode)

        -- Create autocommands to update on mode change
        local group = vim.api.nvim_create_augroup("BlinkIndentModeColor", { clear = true })

        vim.api.nvim_create_autocmd("ModeChanged", {
            group = group,
            callback = function()
                vim.schedule(function()
                    update_indent_color(vim.api.nvim_get_mode().mode)
                end)
            end,
        })

        vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
            group = group,
            callback = function()
                vim.schedule(function()
                    update_indent_color(vim.api.nvim_get_mode().mode)
                end)
            end,
        })
    end,
}
