return {
    "stevearc/conform.nvim",
    -- enabled = false,
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    -- stylua: ignore
    keys = {
        {"<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, mode = "n", desc = "Format"},
        {"<leader>cF", function() require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 }) end, mode = {"n", "v"}, desc = "Format Injected Langs"},
    },
    config = function()
        Snacks.toggle({
            name = "Auto Format",
            get = function()
                return not vim.b.disable_autoformat ~= false
            end,
            set = function(state)
                if state then
                    vim.cmd("FormatEnable!")
                else
                    vim.cmd("FormatDisable!")
                end
            end,
        }):map("<leader>uf")

        require("conform").setup({
            notify_on_error = false,
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_format", "ruff_organize_imports" },
                markdown = { "injected", "prettier" },
                sh = { "shfmt" },
                html = { "prettier" },
                htmldjango = { "djlint" },
                json = { "prettier" },
                css = { "prettier" },
            },
            -- Custom formatter configurations
            formatters = {
                stylua = {
                    args = {
                        "--line-endings",
                        "Unix",
                        "--indent-type",
                        "Spaces",
                        "--indent-width",
                        "4",
                        "--stdin-filepath",
                        "$FILENAME",
                        "-",
                    },
                },
                djlint = {
                    args = { "--reformat", "--indent", "2", "--ignore-case", "-" },
                },
            },
            format_on_save = function(bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                local disable_filetypes = { c = true, cpp = true }
                if disable_filetypes[vim.bo[bufnr].filetype] then
                    return nil
                else
                    return {
                        timeout_ms = 5000,
                        lsp_format = "fallback",
                    }
                end
            end,
        })
        vim.api.nvim_create_user_command("FormatDisable", function(args)
            if args.bang then
                vim.b.disable_autoformat = true
            else
                vim.g.disable_autoformat = true
            end
        end, {
            desc = "Disable autoformat-on-save",
            bang = true,
        })
        vim.api.nvim_create_user_command("FormatEnable", function(args)
            if args.bang then
                vim.b.disable_autoformat = false
            else
                vim.g.disable_autoformat = false
            end
        end, {
            desc = "Re-enable autoformat-on-save",
            bang = true,
        })
    end,
}
