return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local lint = require("lint")

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

        -- Debounced lint function (slightly longer than updatetime)
        local lint_timer = nil
        local function debounced_lint()
            if lint_timer then
                vim.fn.timer_stop(lint_timer)
            end
            lint_timer = vim.fn.timer_start(300, function()
                require("lint").try_lint(nil, { ignore_errors = true })
            end)
        end

        vim.api.nvim_create_autocmd({
            "BufWritePost", -- Always lint on save
            "BufReadPost", -- Lint when opening files
            "InsertLeave", -- Lint when leaving insert mode
            "TextChanged", -- Lint after text changes in normal mode
            "CursorHold", -- Lint after 250ms of inactivity (your updatetime)
        }, {
            group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
            callback = debounced_lint,
        })
    end,
}
