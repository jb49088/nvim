local M = {}

-- Configuration
local config = {
    left = { "mark", "sign" }, -- priority of signs on the left (high to low)
    right = { "fold", "git" }, -- priority of signs on the right (high to low)
    folds = {
        open = true, -- show open fold icons
        git_hl = true, -- use Git Signs hl for fold icons
    },
    git = {
        patterns = { "GitSign", "MiniDiffSign" }, -- patterns to match Git signs
    },
    refresh = 50, -- refresh cache at most every 50ms
}

-- Cache for signs per buffer and line
local sign_cache = {}
local cache = {}
local icon_cache = {}

-- Check if a sign name matches git patterns
local function is_git_sign(name)
    for _, pattern in ipairs(config.git.patterns) do
        if name:find(pattern) then
            return true
        end
    end
    return false
end

-- Get all signs for a buffer
local function buf_signs(buf)
    local signs = {}

    -- Handle legacy signs for Neovim <0.10
    if vim.fn.has("nvim-0.10") == 0 then
        for _, sign in ipairs(vim.fn.sign_getplaced(buf, { group = "*" })[1].signs) do
            local ret = vim.fn.sign_getdefined(sign.name)[1]
            if ret then
                ret.priority = sign.priority
                ret.type = is_git_sign(sign.name) and "git" or "sign"
                signs[sign.lnum] = signs[sign.lnum] or {}
                table.insert(signs[sign.lnum], ret)
            end
        end
    end

    -- Get extmark signs
    local extmarks = vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true, type = "sign" })
    for _, extmark in pairs(extmarks) do
        local lnum = extmark[2] + 1
        signs[lnum] = signs[lnum] or {}
        local name = extmark[4].sign_hl_group or extmark[4].sign_name or ""
        table.insert(signs[lnum], {
            name = name,
            type = is_git_sign(name) and "git" or "sign",
            text = extmark[4].sign_text,
            texthl = extmark[4].sign_hl_group,
            priority = extmark[4].priority,
        })
    end

    -- Add marks
    local marks = vim.fn.getmarklist(buf)
    vim.list_extend(marks, vim.fn.getmarklist())
    for _, mark in ipairs(marks) do
        if mark.pos[1] == buf and mark.mark:match("[a-zA-Z]") then
            local lnum = mark.pos[2]
            signs[lnum] = signs[lnum] or {}
            table.insert(signs[lnum], {
                text = mark.mark:sub(2),
                texthl = "DiagnosticHint",
                type = "mark",
            })
        end
    end

    return signs
end

-- Get signs for a specific line
local function line_signs(win, buf, lnum)
    local buf_signs_data = sign_cache[buf]
    if not buf_signs_data then
        buf_signs_data = buf_signs(buf)
        sign_cache[buf] = buf_signs_data
    end
    local signs = buf_signs_data[lnum] or {}

    -- Get fold signs
    vim.api.nvim_win_call(win, function()
        if vim.fn.foldclosed(lnum) >= 0 then
            signs[#signs + 1] = {
                text = vim.opt.fillchars:get().foldclose or "",
                texthl = "FoldColumn",
                type = "fold",
            }
        elseif config.folds.open and vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) then
            signs[#signs + 1] = {
                text = vim.opt.fillchars:get().foldopen or "",
                texthl = "FoldColumn",
                type = "fold",
            }
        end
    end)

    -- Sort by priority (high to low)
    table.sort(signs, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)

    return signs
end

-- Format sign icon with highlighting
local function icon(sign)
    if not sign then
        return "  "
    end

    local key = (sign.text or "") .. (sign.texthl or "")
    if icon_cache[key] then
        return icon_cache[key]
    end

    local text = vim.fn.strcharpart(sign.text or "", 0, 2)
    text = text .. string.rep(" ", 2 - vim.fn.strchars(text))
    icon_cache[key] = sign.texthl and ("%#" .. sign.texthl .. "#" .. text .. "%*") or text
    return icon_cache[key]
end

-- Main status column function
local function get_statuscolumn()
    local win = vim.g.statusline_winid
    local nu = vim.wo[win].number
    local rnu = vim.wo[win].relativenumber
    local show_signs = vim.v.virtnum == 0 and vim.wo[win].signcolumn ~= "no"
    local components = { "", "", "" } -- left, middle, right

    if not (show_signs or nu or rnu) then
        return ""
    end

    -- Line numbers
    if (nu or rnu) and vim.v.virtnum == 0 then
        local num
        if rnu and nu and vim.v.relnum == 0 then
            num = vim.v.lnum
        elseif rnu then
            num = vim.v.relnum
        else
            num = vim.v.lnum
        end
        components[2] = "%=" .. num .. " "
    end

    -- Signs
    if show_signs then
        local buf = vim.api.nvim_win_get_buf(win)
        local is_file = vim.bo[buf].buftype == ""
        local signs = line_signs(win, buf, vim.v.lnum)

        if #signs > 0 then
            local signs_by_type = {}
            for _, s in ipairs(signs) do
                signs_by_type[s.type] = signs_by_type[s.type] or s
            end

            local function find(types)
                for _, t in ipairs(types) do
                    if signs_by_type[t] then
                        return signs_by_type[t]
                    end
                end
            end

            local left, right = find(config.left), find(config.right)

            -- Apply git highlighting to fold signs if enabled
            if config.folds.git_hl then
                local git = signs_by_type.git
                if git and left and left.type == "fold" then
                    left.texthl = git.texthl
                end
                if git and right and right.type == "fold" then
                    right.texthl = git.texthl
                end
            end

            components[1] = left and icon(left) or "  "
            components[3] = is_file and (right and icon(right) or "  ") or ""
        else
            components[1] = "  "
            components[3] = is_file and "  " or ""
        end
    end

    local ret = table.concat(components, "")
    return "%@v:lua.require'custom.modules.status_column'.click_fold@" .. ret .. "%T"
end

-- Cached version of get_statuscolumn
function M.get()
    local win = vim.g.statusline_winid
    local buf = vim.api.nvim_win_get_buf(win)
    local key = ("%d:%d:%d:%d:%d"):format(win, buf, vim.v.lnum, vim.v.virtnum ~= 0 and 1 or 0, vim.v.relnum)

    if cache[key] then
        return cache[key]
    end

    local ok, ret = pcall(get_statuscolumn)
    if ok then
        cache[key] = ret
        return ret
    end
    return ""
end

-- Handle fold clicking
function M.click_fold()
    local pos = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 1 })
    vim.api.nvim_win_call(pos.winid, function()
        if vim.fn.foldlevel(pos.line) > 0 then
            vim.cmd("normal! za")
        end
    end)
end

-- Set up highlight groups and cache refresh timer
vim.api.nvim_set_hl(0, "CustomStatusColumnMark", { link = "DiagnosticHint", default = true })

local timer = assert((vim.uv or vim.loop).new_timer())
timer:start(config.refresh, config.refresh, function()
    sign_cache = {}
    cache = {}
    icon_cache = {}
end)

return M
