return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")
        -- Configure linters by filetype
        lint.linters_by_ft = {
            lua = { "luacheck" },
        }
        lint.linters.luacheck.args = {
            "--globals",
            "vim",
            "Snacks",
            "--formatter",
            "plain",
            "--codes",
            "--ranges",
            "-",
        }
        -- Create autocommand to run linters
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
            group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
            callback = function()
                require("lint").try_lint(nil, { ignore_errors = true })
            end,
        })
    end,
}
