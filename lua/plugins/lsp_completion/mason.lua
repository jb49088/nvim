return {
    "williamboman/mason.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        ui = {
            border = "rounded",
            backdrop = 100,
        },
    },
}
