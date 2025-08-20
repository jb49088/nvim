return {
    "wesQ3/vim-windowswap",
    enabled = false,
    keys = {
        { "<leader>ww", "<cmd>call WindowSwap#EasyWindowSwap()<CR>", desc = "Swap windows" },
    },
    config = function()
        -- Optional: customize key mappings
        -- vim.g.windowswap_map_keys = 0  -- disable default bindings if you want custom ones
    end,
}
