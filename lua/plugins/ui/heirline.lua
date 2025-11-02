-- ================================================================================
-- =                                HEIRLINE.NVIM                                 =
-- ================================================================================

local path = require("custom.extensions.heirline_path")

return {
    "rebelot/heirline.nvim",
    event = "VeryLazy",
    -- enabled = false,
    config = function()
        local heirline = require("heirline")
        local conditions = require("heirline.conditions")
        local utils = require("heirline.utils")

        -- Mode mapping based on lualine's implementation
        local mode_map = {
            ["n"] = "NORMAL",
            ["no"] = "O-PENDING",
            ["nov"] = "O-PENDING",
            ["noV"] = "O-PENDING",
            ["no\22"] = "O-PENDING",
            ["niI"] = "NORMAL",
            ["niR"] = "NORMAL",
            ["niV"] = "NORMAL",
            ["nt"] = "NORMAL",
            ["ntT"] = "NORMAL",
            ["v"] = "VISUAL",
            ["vs"] = "VISUAL",
            ["V"] = "V-LINE",
            ["Vs"] = "V-LINE",
            ["\22"] = "V-BLOCK",
            ["\22s"] = "V-BLOCK",
            ["s"] = "SELECT",
            ["S"] = "S-LINE",
            ["\19"] = "S-BLOCK",
            ["i"] = "INSERT",
            ["ic"] = "INSERT",
            ["ix"] = "INSERT",
            ["R"] = "REPLACE",
            ["Rc"] = "REPLACE",
            ["Rx"] = "REPLACE",
            ["Rv"] = "V-REPLACE",
            ["Rvc"] = "V-REPLACE",
            ["Rvx"] = "V-REPLACE",
            ["c"] = "COMMAND",
            ["cv"] = "EX",
            ["ce"] = "EX",
            ["r"] = "REPLACE",
            ["rm"] = "MORE",
            ["r?"] = "CONFIRM",
            ["!"] = "SHELL",
            ["t"] = "TERMINAL",
        }

        -- Helper functions
        local function get_mode_name()
            local mode_code = vim.api.nvim_get_mode().mode
            return mode_map[mode_code] or mode_code:upper()
        end

        local function get_mode_color()
            local mode_code = vim.api.nvim_get_mode().mode
            local mode_colors = {
                ["n"] = utils.get_highlight("ModeColorNormal").fg,
                ["i"] = utils.get_highlight("ModeColorInsert").fg,
                ["v"] = utils.get_highlight("ModeColorVisual").fg,
                ["V"] = utils.get_highlight("ModeColorVisual").fg,
                ["\22"] = utils.get_highlight("ModeColorVisual").fg,
                ["s"] = utils.get_highlight("ModeColorVisual").fg,
                ["S"] = utils.get_highlight("ModeColorVisual").fg,
                ["\19"] = utils.get_highlight("ModeColorVisual").fg,
                ["c"] = utils.get_highlight("ModeColorCommand").fg,
                ["R"] = utils.get_highlight("ModeColorReplace").fg,
                ["Rc"] = utils.get_highlight("ModeColorReplace").fg,
                ["Rx"] = utils.get_highlight("ModeColorReplace").fg,
                ["Rv"] = utils.get_highlight("ModeColorReplace").fg,
                ["Rvc"] = utils.get_highlight("ModeColorReplace").fg,
                ["Rvx"] = utils.get_highlight("ModeColorReplace").fg,
                ["r"] = utils.get_highlight("ModeColorReplace").fg,
                ["t"] = utils.get_highlight("ModeColorTerminal").fg,
            }
            return mode_colors[mode_code] or utils.get_highlight("ModeColorNormal").fg
        end

        -- Helper functions to create conditional components with space
        local function with_trailing_space(component)
            return {
                component,
                { condition = component.condition, provider = "  " },
            }
        end

        local function with_leading_space(component)
            return {
                { condition = component.condition, provider = "  " },
                component,
            }
        end

        local ViMode = {
            {
                provider = function()
                    return " " .. get_mode_name() .. " "
                end,
                hl = function()
                    return {
                        bg = get_mode_color(),
                        fg = "black",
                        bold = false,
                    }
                end,
            },
            {
                provider = "",
                hl = function()
                    return { fg = get_mode_color() }
                end,
            },
        }

        local FileEncoding = {
            condition = function()
                -- Check if current window is a floating window
                local win_config = vim.api.nvim_win_get_config(0)
                local is_floating = win_config.relative ~= ""

                -- Check if buffer has no name
                local bufname = vim.api.nvim_buf_get_name(0)

                -- Hide component if in a floating window or no name buffer
                return not is_floating and bufname ~= ""
            end,
            provider = function()
                local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
                return enc
            end,
        }

        local FileFormat = {
            condition = function()
                -- Check if current window is a floating window
                local win_config = vim.api.nvim_win_get_config(0)
                local is_floating = win_config.relative ~= ""

                -- Check if buffer has no name
                local bufname = vim.api.nvim_buf_get_name(0)
                local is_no_name = bufname == ""

                -- Hide component if in a floating window or no name buffer
                return not is_floating and not is_no_name
            end,
            provider = function()
                local fileformat_symbols = {
                    unix = "",
                    dos = "",
                    mac = "",
                }
                local format = vim.bo.fileformat
                local symbol = fileformat_symbols[format] or format
                return symbol
            end,
        }

        local GitBranch = {
            condition = function()
                return vim.b.gitsigns_head and not vim.b.gitsigns_git_status
            end,
            provider = function()
                local gs = vim.b.gitsigns_status_dict
                if not gs then
                    return ""
                end
                return "󰘬 " .. gs.head
            end,
            update = {
                "User",
                pattern = "GitSignsUpdate",
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

        local GitDiffs = {
            condition = function()
                local gs = vim.b.gitsigns_status_dict
                if not gs then
                    return false
                end
                -- Only show if there are actual changes
                return (gs.added and gs.added > 0) or (gs.changed and gs.changed > 0) or (gs.removed and gs.removed > 0)
            end,
            init = function(self)
                self.status_dict = vim.b.gitsigns_status_dict
            end,
            static = {
                symbols = { added = " ", modified = " ", removed = " " },
            },
            {
                provider = function(self)
                    if not self.status_dict or not self.status_dict.added or self.status_dict.added == 0 then
                        return ""
                    end
                    local is_first = true
                    return (is_first and "" or " ") .. self.symbols.added .. self.status_dict.added
                end,
                hl = "GitSignsAdd",
            },
            {
                provider = function(self)
                    if not self.status_dict or not self.status_dict.changed or self.status_dict.changed == 0 then
                        return ""
                    end
                    local is_first = not (self.status_dict.added and self.status_dict.added > 0)
                    return (is_first and "" or " ") .. self.symbols.modified .. self.status_dict.changed
                end,
                hl = "GitSignsChange",
            },
            {
                provider = function(self)
                    if not self.status_dict or not self.status_dict.removed or self.status_dict.removed == 0 then
                        return ""
                    end
                    local is_first = not (
                        (self.status_dict.added and self.status_dict.added > 0)
                        or (self.status_dict.changed and self.status_dict.changed > 0)
                    )
                    return (is_first and "" or " ") .. self.symbols.removed .. self.status_dict.removed
                end,
                hl = "GitSignsDelete",
            },
        }

        -- Helper function to check if a plugin is available
        local function is_available(plugin)
            local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
            return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
        end

        -- Check plugin availability once during setup
        local has_conform = is_available("conform.nvim")
        local has_lint = is_available("nvim-lint")

        -- Helper to normalize ruff variants
        local function normalize_name(name)
            return name:match("^ruff") and "ruff" or name
        end

        local ActiveTooling = {
            flexible = 3,
            {
                condition = function(self)
                    local bufnr = self and self.bufnr or 0
                    local ft = vim.bo[bufnr].filetype

                    -- Check LSP first (fastest)
                    if next(vim.lsp.get_clients({ bufnr = bufnr })) then
                        return true
                    end

                    -- Check if conform has formatters
                    if has_conform and package.loaded["conform"] then
                        local ok, conform = pcall(require, "conform")
                        if ok then
                            local formatters = conform.list_formatters(bufnr)
                            if #formatters > 0 then
                                return true
                            end
                        end
                    end

                    -- Check if nvim-lint has linters
                    if has_lint and package.loaded["lint"] then
                        local ok, lint = pcall(require, "lint")
                        if ok and lint.linters_by_ft[ft] and #lint.linters_by_ft[ft] > 0 then
                            return true
                        end
                    end

                    return false
                end,

                update = {
                    "LspAttach",
                    "LspDetach",
                    "BufEnter",
                    callback = function()
                        local mode = vim.api.nvim_get_mode().mode
                        if mode ~= "i" and mode ~= "ic" and mode ~= "ix" then
                            vim.schedule(vim.cmd.redrawstatus)
                        end
                    end,
                },

                provider = function(self)
                    local bufnr = self and self.bufnr or 0
                    local all_tools = {}
                    local seen_tools = {}
                    local ft = vim.bo[bufnr].filetype

                    -- Add LSP clients
                    for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
                        local normalized = normalize_name(client.name)
                        if not seen_tools[normalized] then
                            table.insert(all_tools, normalized)
                            seen_tools[normalized] = true
                        end
                    end

                    -- Add shellcheck for bash files when bashls is active
                    if (ft == "sh" or ft == "bash") and vim.fn.executable("shellcheck") == 1 then
                        for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
                            if client.name == "bashls" then
                                if not seen_tools["shellcheck"] then
                                    table.insert(all_tools, "shellcheck")
                                    seen_tools["shellcheck"] = true
                                end
                                break
                            end
                        end
                    end

                    -- Only check conform if it's loaded (not just available)
                    if has_conform and package.loaded["conform"] then
                        local ok, conform = pcall(require, "conform")
                        if ok then
                            local formatters = conform.list_formatters(bufnr)
                            for _, formatter in ipairs(formatters) do
                                local normalized = normalize_name(formatter.name)
                                if not seen_tools[normalized] then
                                    table.insert(all_tools, normalized)
                                    seen_tools[normalized] = true
                                end
                            end
                        end
                    end

                    -- Only check nvim-lint if it's loaded (not just available)
                    if has_lint and package.loaded["lint"] then
                        local ok, lint = pcall(require, "lint")
                        if ok and lint.linters_by_ft[ft] then
                            for _, linter in ipairs(lint.linters_by_ft[ft]) do
                                local normalized = normalize_name(linter)
                                if not seen_tools[normalized] then
                                    table.insert(all_tools, normalized)
                                    seen_tools[normalized] = true
                                end
                            end
                        end
                    end

                    return #all_tools > 0 and table.concat(all_tools, ", ") or ""
                end,
            },
            -- Fallback when no LSP clients
            {
                provider = "",
            },
        }

        local Diagnostics = {
            condition = function()
                -- Hide diagnostics in insert mode
                local mode = vim.api.nvim_get_mode().mode
                if mode == "i" or mode == "ic" or mode == "ix" then
                    return false
                end

                return conditions.has_diagnostics
            end,
            static = {
                error_icon = vim.diagnostic.config().signs.text[vim.diagnostic.severity.ERROR],
                warn_icon = vim.diagnostic.config().signs.text[vim.diagnostic.severity.WARN],
                info_icon = vim.diagnostic.config().signs.text[vim.diagnostic.severity.INFO],
                hint_icon = vim.diagnostic.config().signs.text[vim.diagnostic.severity.HINT],
            },
            init = function(self)
                self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
                self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
                self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
                self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
            end,
            update = {
                "DiagnosticChanged",
                "BufEnter",
                "ModeChanged", -- Add this to update when mode changes
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                    vim.cmd("redrawtabline")
                end),
            },
            {
                provider = function(self)
                    if self.errors == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = true

                    return (is_first and "" or " ") .. self.error_icon .. self.errors
                end,
                hl = "DiagnosticError",
            },
            {
                provider = function(self)
                    if self.warnings == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = self.errors == 0

                    return (is_first and "" or " ") .. self.warn_icon .. self.warnings
                end,
                hl = "DiagnosticWarn",
            },
            {
                provider = function(self)
                    if self.info == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = self.errors == 0 and self.warnings == 0

                    return (is_first and "" or " ") .. self.info_icon .. self.info
                end,
                hl = "DiagnosticInfo",
            },
            {
                provider = function(self)
                    if self.hints == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = self.errors == 0 and self.warnings == 0 and self.info == 0

                    return (is_first and "" or " ") .. self.hint_icon .. self.hints
                end,
                hl = "DiagnosticHint",
            },
        }

        local LineColumn = {
            condition = function()
                local win_config = vim.api.nvim_win_get_config(0)
                local is_floating = win_config.relative ~= ""

                local bufname = vim.api.nvim_buf_get_name(0)

                return not is_floating and bufname ~= ""
            end,
            provider = function()
                return string.format("%d:%d", vim.fn.line("."), vim.fn.col("."))
            end,
        }

        local FilePercent = {
            condition = function()
                -- Check if current window is a floating window
                local win_config = vim.api.nvim_win_get_config(0)
                local is_floating = win_config.relative ~= ""

                local bufname = vim.api.nvim_buf_get_name(0)

                -- Hide component if in a floating window or no name buffer
                return not is_floating and bufname ~= ""
            end,
            provider = function()
                local line, total = vim.fn.line("."), vim.fn.line("$")
                if line == 1 then
                    return "top"
                elseif line == total then
                    return "bot"
                else
                    return string.format("%d%%%%", math.floor((line / total) * 100))
                end
            end,
        }

        local Clock = {
            {
                provider = "",
                hl = function()
                    return { fg = get_mode_color() }
                end,
            },
            {
                provider = function()
                    return "  " .. os.date("%H:%M") .. " "
                end,
                hl = function()
                    return {
                        bg = get_mode_color(),
                        fg = "black",
                        bold = false,
                    }
                end,
            },
            update = {
                "ModeChanged",
                "User",
                pattern = { "*:*", "HeirlineClockUpdate" },
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

        -- Setup global timer and autocmd for clock updates (only once)
        local uv = vim.uv or vim.loop
        uv.new_timer():start(
            (60 - tonumber(os.date("%S"))) * 1000,
            60000,
            vim.schedule_wrap(function()
                vim.api.nvim_exec_autocmds("User", { pattern = "HeirlineClockUpdate", modeline = false })
            end)
        )

        -- Statusline layout using the helper functions consistently
        local statusline = {
            with_trailing_space(ViMode),
            with_trailing_space(GitBranch),
            with_trailing_space(GitDiffs),
            with_trailing_space(path.component),
            with_trailing_space(Diagnostics),
            { provider = "%=" },
            with_leading_space(ActiveTooling),
            with_leading_space(FileEncoding),
            with_leading_space(FileFormat),
            with_leading_space(LineColumn),
            with_leading_space(FilePercent),
            with_leading_space(Clock),
        }
        heirline.setup({
            statusline = statusline,
        })
    end,
}
