local active_venv = nil
return function()
    local gui_utils = require("venv-selector.gui.utils")
    local search = require("venv-selector.search")
    local results = {}

    -- Helper function to extract venv name from path
    local function extract_venv_name(name)
        local parts = {}
        for part in string.gmatch(name, "[^/]+") do
            table.insert(parts, part)
        end
        -- Look for common venv directory patterns
        for i = 1, #parts - 1 do
            if parts[i] == "venvs" or parts[i] == "envs" or parts[i] == ".venv" or parts[i] == "virtualenvs" then
                if parts[i + 1] and parts[i + 1] ~= "bin" then
                    local venv_name = parts[i + 1]
                    local before_venv = string.sub(name, 1, string.find(name, venv_name) - 1)
                    local after_venv = string.sub(name, string.find(name, venv_name) + string.len(venv_name))
                    return venv_name, before_venv, after_venv
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

    local function create_picker()
        return Snacks.picker.pick({
            title = "Virtual Environments",
            finder = function()
                return results
            end,
            layout = { preset = "select" },
            format = function(item)
                local venv_name, before_venv, after_venv = extract_venv_name(item.name)
                local is_active = active_venv and item.name == active_venv
                local result = {
                    { item.icon, is_active and "VenvPickerActive" or "SnacksPickerDir" },
                    { " " },
                }
                if venv_name then
                    if before_venv ~= "" then
                        table.insert(result, { before_venv, "SnacksPickerDir" })
                    end
                    table.insert(result, { venv_name, "SnacksPickerFile" })
                    if after_venv ~= "" then
                        table.insert(result, { after_venv, "SnacksPickerDir" })
                    end
                else
                    table.insert(result, { item.name, "SnacksPickerDir" })
                end

                return result
            end,
            confirm = function(picker, item)
                if item then
                    -- Check if selecting the same venv that's already active
                    if active_venv and item.name == active_venv then
                        -- Deactivate the current venv
                        require("venv-selector").deactivate()
                        picker:close()
                        vim.schedule(function()
                            active_venv = nil
                            vim.notify("Virtual environment deactivated", vim.log.levels.INFO)
                        end)
                    else
                        -- Activate the selected venv
                        gui_utils.select(item)
                        picker:close()
                        vim.schedule(function()
                            active_venv = item.name
                        end)
                    end
                end
            end,
        })
    end

    local picker = nil
    local search_handler = {
        insert_result = function(_, result)
            result.text = result.source .. " " .. result.name
            table.insert(results, result)
            if picker then
                picker:find()
            else
                picker = create_picker()
            end
        end,
        search_done = function(_)
            results = gui_utils.remove_dups(results)
            table.sort(results, function(a, b)
                return a.name < b.name
            end)
            if picker then
                picker:find()
            end
        end,
    }

    search.run_search(search_handler, nil)
end
