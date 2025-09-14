return {
    "nvim-treesitter/nvim-treesitter",
    -- enabled = false,
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        -- Setup with proper install directory
        local install_dir = vim.fn.stdpath("data") .. "/site"
        require("nvim-treesitter").setup({
            install_dir = install_dir,
        })

        -- Ensure install directory is in runtimepath
        vim.opt.runtimepath:prepend(install_dir)

        -- Install parsers
        require("nvim-treesitter").install({
            "bash",
            "c",
            "diff",
            "html",
            "json",
            "lua",
            "luadoc",
            "markdown",
            "markdown_inline",
            "query",
            "vim",
            "vimdoc",
            "python",
        })

        -- Enable highlighting
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "python", "json", "lua", "sh", "c", "html", "markdown", "vim", "ruby" },
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}
