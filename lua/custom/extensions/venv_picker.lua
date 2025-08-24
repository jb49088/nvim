return function(venv_manager)
    -- Helper function to extract venv name from python path and split the path
    local function extract_venv_name_parts(python_path)
        local parts = {}
        for part in string.gmatch(python_path, "[^/]+") do
            table.insert(parts, part)
        end

        -- Look for common venv directory patterns
        for i = 1, #parts - 1 do
            if parts[i] == "venvs" or parts[i] == "envs" or parts[i] == ".venv" or parts[i] == "virtualenvs" then
                if parts[i + 1] and parts[i + 1] ~= "bin" then
                    local venv_name = parts[i + 1]
                    local before_venv = string.sub(python_path, 1, string.find(python_path, venv_name) - 1)
                    local after_venv =
                        string.sub(python_path, string.find(python_path, venv_name) + string.len(venv_name))
                    return venv_name, before_venv, after_venv
                end
            end
        end

        -- Fallback: look for pattern where second-to-last directory might be venv name
        if #parts >= 3 and parts[#parts] == "python" and parts[#parts - 1] == "bin" then
            local venv_name = parts[#parts - 2]
            local before_venv = string.sub(python_path, 1, string.find(python_path, venv_name) - 1)
            local after_venv = string.sub(python_path, string.find(python_path, venv_name) + string.len(venv_name))
            return venv_name, before_venv, after_venv
        end

        return nil, python_path, ""
    end

    -- Check if Snacks is available
    local ok, snacks = pcall(require, "snacks")
    if not ok then
        vim.notify("Snacks picker not available", vim.log.levels.ERROR)
        return
    end

    local venvs = venv_manager.find_venvs()

    if #venvs == 0 then
        vim.notify("No virtual environments found", vim.log.levels.WARN)
        return
    end

    -- Prepare items for Snacks picker
    local items = {}
    for _, venv in ipairs(venvs) do
        table.insert(items, {
            text = venv.python_path, -- Use full path for display
            venv_info = venv,
        })
    end

    return snacks.picker.pick({
        title = "Virtual Environments",
        items = items,
        layout = { preset = "select" },
        format = function(item)
            local current_python = venv_manager.current_python()
            local is_active = current_python == item.venv_info.python_path
            local icon = "󰌠"
            local icon_hl = is_active and "VenvPickerActive" or "SnacksPickerDir"

            -- Extract path parts for highlighting
            local venv_name, before_venv, after_venv = extract_venv_name_parts(item.venv_info.python_path)

            local result = {
                { icon .. " ", icon_hl },
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
                table.insert(result, { item.venv_info.python_path, "SnacksPickerDir" })
            end

            return result
        end,
        confirm = function(picker, item)
            if item then
                local current_python = venv_manager.current_python()
                local is_active = current_python == item.venv_info.python_path

                picker:close()
                vim.schedule(function()
                    if is_active then
                        -- Deactivate if already active
                        venv_manager.deactivate()
                    else
                        -- Activate the selected venv
                        venv_manager.activate(item.venv_info)
                    end
                end)
            end
        end,
    })
end
