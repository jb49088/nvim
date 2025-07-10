local active_venv = nil

return function()
    local gui_utils = require("venv-selector.gui.utils")
    local search = require("venv-selector.search")

    local M = {}
    M.__index = M

    -- Custom function to get icon highlight based on selection
    local function get_icon_highlight(item)
        if active_venv and item.name == active_venv then
            return "VenvSelectActive"
        else
            return "SnacksPickerDir"
        end
    end

    -- Helper function to extract venv name from path
    local function extract_venv_name(name)
        -- Handle paths like "/home/main/venvs/scraper/bin/python"
        -- Extract the venv name (e.g., "scraper") from the path
        local parts = {}
        for part in string.gmatch(name, "[^/]+") do
            table.insert(parts, part)
        end
        -- Look for common venv directory patterns
        for i = 1, #parts - 1 do
            if parts[i] == "venvs" or parts[i] == "envs" or parts[i] == ".venv" or parts[i] == "virtualenvs" then
                if parts[i + 1] and parts[i + 1] ~= "bin" then
                    return parts[i + 1],
                        string.sub(name, 1, string.find(name, parts[i + 1]) - 1),
                        string.sub(name, string.find(name, parts[i + 1]) + string.len(parts[i + 1]))
                end
            end
        end
        -- Fallback: look for pattern where second-to-last directory might be venv name
        if #parts >= 3 and parts[#parts] == "python" and parts[#parts - 1] == "bin" then
            local venv_name = parts[#parts - 2]
            local before_venv = string.sub(name, 1, string.find(name, venv_name) - 1)
            local after_venv = string.sub(name, string.find(name, venv_name) + string.len(venv_name))
            return venv_name, before_venv, after_venv
        end
        return nil, name, ""
    end

    function M.new()
        local self = setmetatable({ results = {}, picker = nil }, M)
        return self
    end

    function M:pick()
        return Snacks.picker.pick({
            title = "Virtual Environments",
            finder = function(opts, ctx)
                return self.results
            end,
            layout = {
                preset = "select",
            },
            format = function(item, picker)
                local venv_name, before_venv, after_venv = extract_venv_name(item.name)
                local name_parts = {}
                if venv_name then
                    -- If we found a venv name, highlight it differently
                    if before_venv ~= "" then
                        table.insert(name_parts, { before_venv, "SnacksPickerDir" })
                    end
                    table.insert(name_parts, { venv_name, "SnacksPickerFile" })
                    if after_venv ~= "" then
                        table.insert(name_parts, { after_venv, "SnacksPickerDir" })
                    end
                else
                    -- Fallback to original formatting
                    table.insert(name_parts, { item.name, "SnacksPickerDir" })
                end
                local result = {
                    { item.icon, get_icon_highlight(item) },
                    { " " },
                }
                -- Add the formatted name parts
                for _, part in ipairs(name_parts) do
                    table.insert(result, part)
                end
                return result
            end,
            confirm = function(picker, item)
                if item then
                    gui_utils.select(item)
                    picker:close()
                    -- Delay the color change to avoid flash
                    vim.schedule(function()
                        active_venv = item.name
                    end)
                end
            end,
        })
    end

    function M:insert_result(result)
        result.text = result.source .. " " .. result.name
        table.insert(self.results, result)
        if self.picker then
            self.picker:find()
        else
            self.picker = self:pick()
        end
    end

    function M:search_done()
        self.results = gui_utils.remove_dups(self.results)
        -- Custom sorting: alphabetical by name instead of active venv first
        table.sort(self.results, function(a, b)
            return a.name < b.name
        end)
        self.picker:find()
    end

    search.run_search(M.new(), nil)
end
