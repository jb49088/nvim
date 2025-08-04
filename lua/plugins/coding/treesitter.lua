return {
    "nvim-treesitter/nvim-treesitter",
    -- enabled = false,
    branch = "main",
    event = "VeryLazy",
    build = ":TSUpdate",
    config = function()
        -- Setup with proper install directory
        local install_dir = vim.fn.stdpath("data") .. "/site"
        require("nvim-treesitter").setup({
            install_dir = install_dir,
        })

        -- Ensure install directory is in runtimepath
        vim.opt.runtimepath:prepend(install_dir)

        -- Install parsers (same as your ensure_installed list)
        require("nvim-treesitter").install({
            "bash",
            "c",
            "diff",
            "html",
            "lua",
            "luadoc",
            "markdown",
            "markdown_inline",
            "query",
            "vim",
            "vimdoc",
            "python",
        })

        -- Enable treesitter features
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "python", "lua", "bash", "c", "html", "markdown", "vim", "ruby" },
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}
