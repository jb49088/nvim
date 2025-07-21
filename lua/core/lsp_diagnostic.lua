vim.diagnostic.config({
    severity_sort = true,
    float = { border = "rounded", header = "", source = true },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = vim.g.have_nerd_font and {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
    } or {},
    virtual_text = {
        prefix = "",
        source = false,
        spacing = 2,
    },
    -- update_in_insert = true,
})
