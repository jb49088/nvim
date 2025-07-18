-- lua/custom/integrations/mode_heirline_color.lua

local M = {} -- This table will hold the exported components

-- Define static mappings for mode to highlight group names as local variables
-- These are accessible by the 'BaseSeparator' functions directly.
local mode_highlights = {
    n = "ModeColorNormal",
    i = "ModeColorInsert",
    v = "ModeColorVisual",
    V = "ModeColorVisual",
    c = "ModeColorCommand",
    t = "ModeColorTerminal",
    R = "ModeColorReplace",
    -- Add more modes if needed.
}

-- Fallback highlight group if a specific mode is not defined.
local default_highlight = "ModeColorNormal"

-- Define a base separator component that can be reused
-- and will determine its highlight based on the current mode.
local BaseSeparator = {
    -- Initialize the component by getting the current mode.
    -- This data will be available to 'hl' and 'provider' functions.
    init = function(self)
        self.mode = vim.fn.mode(1)
    end,

    -- The highlight function accesses the mode from 'self.mode'
    -- and the mappings from the local variables.
    hl = function(self)
        -- Get the highlight group name for the current mode,
        -- falling back to the default if not found.
        local highlight_group = mode_highlights[self.mode] or default_highlight
        return highlight_group
    end,

    -- Re-evaluate the component only on ModeChanged event.
    -- This is crucial for dynamic updates.
    update = {
        "ModeChanged",
        pattern = "*:*",
        callback = vim.schedule_wrap(function()
            vim.cmd("redrawstatus")
        end),
    },
}

-- Define the s_left component, creating a new table and merging BaseSeparator's fields
M.s_left = vim.tbl_deep_extend("force", {}, BaseSeparator, {
    provider = "", -- Set the specific provider for the left separator
})

-- Define the s_right component, creating a new table and merging BaseSeparator's fields
M.s_right = vim.tbl_deep_extend("force", {}, BaseSeparator, {
    provider = "", -- Set the specific provider for the right separator
})

return M
