return {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        require("hlchunk").setup({
            chunk = {
                enable = true,
                style = {
                    { fg = "#5EB7FF" },
                    { fg = "#F8747E" },
                },
                use_treesitter = true,
                chars = {
                    right_arrow = "─",
                },
                error_sign = false,
                duration = 0,
                delay = 0,
            },
            indent = {
                enable = true,
                delay = 0,
            },
        })

        -- HACK: Add support for Python list nodes as chunks
        local chunkHelper = require("hlchunk.utils.chunkHelper")
        local original_get_chunk_range = chunkHelper.get_chunk_range

        chunkHelper.get_chunk_range = function(opts)
            local ret_code, range = original_get_chunk_range(opts)

            -- If no chunk found and using treesitter, check for list nodes
            if ret_code == chunkHelper.CHUNK_RANGE_RET.NO_CHUNK and opts.use_treesitter then
                local treesitter = vim.treesitter
                local cursor_node = treesitter.get_node({
                    ignore_injections = false,
                    bufnr = opts.pos.bufnr,
                    pos = { opts.pos.row, opts.pos.col },
                })

                -- Walk up the tree looking for list nodes
                while cursor_node do
                    local node_type = cursor_node:type()
                    local node_start, _, node_end, _ = cursor_node:range()

                    -- Treat list nodes as valid chunks (same as dictionary/tuple)
                    if node_start ~= node_end and node_type == "list" then
                        local Scope = require("hlchunk.utils.scope")
                        return cursor_node:has_error() and chunkHelper.CHUNK_RANGE_RET.CHUNK_ERR
                            or chunkHelper.CHUNK_RANGE_RET.OK,
                            Scope(opts.pos.bufnr, node_start, node_end)
                    end

                    local parent_node = cursor_node:parent()
                    if parent_node == cursor_node then
                        break
                    end
                    cursor_node = parent_node
                end
            end

            return ret_code, range
        end

        -- Helper function to check if a window is floating
        local function is_floating_win(winid)
            local config = vim.api.nvim_win_get_config(winid or 0)
            return config.relative ~= ""
        end

        -- Track the last regular window
        local last_regular_win = nil

        -- Auto commands to show chunks only in active buffer
        local group = vim.api.nvim_create_augroup("hlchunk_focus", { clear = true })
        vim.api.nvim_create_autocmd({ "WinEnter" }, {
            group = group,
            callback = function()
                local current_win = vim.api.nvim_get_current_win()
                if is_floating_win(current_win) then
                    -- Entering floating window - keep hlchunk on previous buffer
                    return
                end
                -- Disable hlchunk on previous regular window if different
                if
                    last_regular_win
                    and last_regular_win ~= current_win
                    and vim.api.nvim_win_is_valid(last_regular_win)
                then
                    vim.api.nvim_win_call(last_regular_win, function()
                        vim.cmd("DisableHLChunk")
                    end)
                end
                -- Enable hlchunk on current regular window
                vim.cmd("EnableHLChunk")
                last_regular_win = current_win
            end,
        })

        -- Initialize hlchunk on startup
        local current_win = vim.api.nvim_get_current_win()
        if not is_floating_win(current_win) then
            vim.cmd("EnableHLChunk")
            last_regular_win = current_win
        end
    end,
}
