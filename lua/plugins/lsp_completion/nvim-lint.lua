-- ================================================================================
-- =                                  NVIM-LINT                                   =
-- ================================================================================

return {
    "mfussenegger/nvim-lint",
    -- enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")
        lint.linters_by_ft = {
            lua = { "luacheck" },
            html = { "htmlhint" },
            htmldjango = { "djlint" },
        }
        lint.linters.luacheck.args = {
            "--globals",
            "vim",
            "Snacks",
            "rep",
            "--formatter",
            "plain",
            "--codes",
            "--ranges",
            "-",
        }
        -- Create autocommand to run linters
        local lint_timer = nil
        vim.api.nvim_create_autocmd({
            "BufWritePost",
            "BufReadPost",
            "InsertLeave",
            "TextChanged",
        }, {
            group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
            callback = function()
                if lint_timer then
                    vim.fn.timer_stop(lint_timer)
                end
                lint_timer = vim.fn.timer_start(100, function()
                    require("lint").try_lint(nil, { ignore_errors = true })
                end)
            end,
        })
    end,
}
