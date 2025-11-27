-- ================================================================================
-- =                                 MINI_SNIPPETS                                =
-- ================================================================================

return {
    "echasnovski/mini.snippets",
    -- enabled = false,
    event = "VeryLazy",
    version = "*",
    config = function()
        local gen_loader = require("mini.snippets").gen_loader
        local snippets = require("mini.snippets")

        snippets.setup({
            snippets = {
                gen_loader.from_lang(),
            },
        })

        -- Override default_insert to disable virtual text
        local default_insert = snippets.default_insert
        snippets.config.expand.insert = function(snippet)
            return default_insert(snippet, {
                empty_tabstop = "", -- Disable • for regular tabstops
                empty_tabstop_final = "", -- Disable ∎ for final tabstop
            })
        end

        -- Set all tabstop highlights to Visual
        vim.api.nvim_set_hl(0, "MiniSnippetsCurrent", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MiniSnippetsCurrentReplace", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MiniSnippetsVisited", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MiniSnippetsUnvisited", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MiniSnippetsFinal", { link = "Visual" })

        -- Auto-stop snippet session when leaving insert mode
        vim.api.nvim_create_autocmd("InsertLeave", {
            callback = function()
                if snippets.session.get() then
                    snippets.session.stop()
                end
            end,
        })
    end,
}
