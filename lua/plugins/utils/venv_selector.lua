local venv_picker = require("custom.integrations.venv_picker")

return {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
    },
    event = "VeryLazy",
    branch = "regexp",
    keys = {
        -- { "<leader>v", "<cmd>VenvSelect<cr>", desc = "Virtual Environments" },
        { "<leader>v", venv_picker, desc = "Virtual Environments" },
    },
    opts = {
        options = {
            -- picker = "native",
            enable_default_searches = false,
            enable_cached_venvs = false,
            cached_venv_automatic_activation = false,
            notify_user_on_venv_activation = true,
        },
        search = {
            venvs = {
                command = "fd '/bin/python$' ~/venvs --full-path -E /proc",
            },
        },
    },
}
