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
                        bold = true,
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

                -- Hide component if in a floating window
                return not is_floating
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

                -- Hide component if in a floating window
                return not is_floating
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
                if not vim.b.gitsigns_head or vim.b.gitsigns_git_status then
                    return false
                end
                local gs = vim.b.gitsigns_status_dict
                if not gs then
                    return false
                end
                -- Only show if there are actual changes
                return (gs.added and gs.added > 0) or (gs.changed and gs.changed > 0) or (gs.removed and gs.removed > 0)
            end,
            static = {
                symbols = {
                    added = " ",
                    modified = " ",
                    removed = " ",
                },
            },
            {
                provider = function(self)
                    local gs = vim.b.gitsigns_status_dict
                    if not gs or not gs.added or gs.added == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = true

                    return (is_first and "" or " ") .. self.symbols.added .. gs.added
                end,
                hl = { fg = utils.get_highlight("GitSignsAdd").fg },
            },
            {
                provider = function(self)
                    local gs = vim.b.gitsigns_status_dict
                    if not gs or not gs.changed or gs.changed == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = not (gs.added and gs.added > 0)

                    return (is_first and "" or " ") .. self.symbols.modified .. gs.changed
                end,
                hl = { fg = utils.get_highlight("GitSignsChange").fg },
            },
            {
                provider = function(self)
                    local gs = vim.b.gitsigns_status_dict
                    if not gs or not gs.removed or gs.removed == 0 then
                        return ""
                    end

                    -- Check if this is the first non-empty component
                    local is_first = not ((gs.added and gs.added > 0) or (gs.changed and gs.changed > 0))

                    return (is_first and "" or " ") .. self.symbols.removed .. gs.removed
                end,
                hl = { fg = utils.get_highlight("GitSignsDelete").fg },
            },
            update = {
                "User",
                pattern = "GitSignsUpdate",
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

        local ToolingActive = {
            condition = function()
                -- Show if any tooling is available (LSP, linters, or formatters)
                local has_lsp = next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
                local has_lint = false
                local has_format = false

                -- Check for linters
                local ok_lint, lint = pcall(require, "lint")
                if ok_lint then
                    local ft = vim.bo.filetype
                    has_lint = lint.linters_by_ft[ft] and #lint.linters_by_ft[ft] > 0
                end

                -- Check for formatters
                local ok_conform, conform = pcall(require, "conform")
                if ok_conform then
                    local formatters = conform.list_formatters(0)
                    has_format = #formatters > 0
                end

                return has_lsp or has_lint or has_format
            end,

            update = { "LspAttach", "LspDetach", "BufEnter", "FileType" },

            provider = function()
                local components = {}
                local ft = vim.bo.filetype

                -- Get LSPs
                local lsp_names = {}
                for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                    table.insert(lsp_names, server.name)
                end
                if #lsp_names > 0 then
                    table.insert(components, "LSP: " .. table.concat(lsp_names, ", "))
                end

                -- Get linters
                local ok_lint, lint = pcall(require, "lint")
                if ok_lint and lint.linters_by_ft[ft] then
                    local linters = lint.linters_by_ft[ft]
                    if #linters > 0 then
                        table.insert(components, "Lint: " .. table.concat(linters, ", "))
                    end
                end

                -- Get formatters
                local ok_conform, conform = pcall(require, "conform")
                if ok_conform then
                    local formatters = conform.list_formatters(0)
                    local formatter_names = {}
                    for _, formatter in ipairs(formatters) do
                        table.insert(formatter_names, formatter.name)
                    end
                    if #formatter_names > 0 then
                        table.insert(components, "Format: " .. table.concat(formatter_names, ", "))
                    end
                end

                -- Compact version with ruff deduplication
                local all_tools = {}
                local seen_tools = {}

                -- Helper to normalize ruff variants
                local function normalize_name(name)
                    if name:match("^ruff") then
                        return "ruff"
                    end
                    return name
                end

                -- Add LSPs
                for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                    local normalized = normalize_name(server.name)
                    if not seen_tools[normalized] then
                        table.insert(all_tools, normalized)
                        seen_tools[normalized] = true
                    end
                end

                -- Add linters
                if ok_lint and lint.linters_by_ft[ft] then
                    for _, linter in ipairs(lint.linters_by_ft[ft]) do
                        local normalized = normalize_name(linter)
                        if not seen_tools[normalized] then
                            table.insert(all_tools, normalized)
                            seen_tools[normalized] = true
                        end
                    end
                end

                -- Add formatters
                if ok_conform then
                    local formatters = conform.list_formatters(0)
                    for _, formatter in ipairs(formatters) do
                        local normalized = normalize_name(formatter.name)
                        if not seen_tools[normalized] then
                            table.insert(all_tools, normalized)
                            seen_tools[normalized] = true
                        end
                    end
                end

                return table.concat(all_tools, ", ")
            end,
        }

        local Diagnostics = {
            condition = conditions.has_diagnostics,
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

                return not is_floating
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

                -- Hide component if in a floating window
                return not is_floating
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
                        bold = true,
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
            with_leading_space(ToolingActive),
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
