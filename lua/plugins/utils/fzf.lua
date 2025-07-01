return {
    "ibhagwan/fzf-lua",
    dependencies = {},
    opts = {}, -- optional: pass your config here
    config = function(_, opts)
        require("fzf-lua").setup(opts)
    end,
}
