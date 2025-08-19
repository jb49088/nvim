-- module to update terminals in realtime when chaning directories and switching venvs
local M = {}

-- Send commands to existing terminal buffers to update their environment
local function update_terminals_venv(venv_path, venv_name)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_is_loaded(buf) then
            local chan = vim.bo[buf].channel
            if chan and chan > 0 then
                if venv_path and venv_name then
                    -- Activate venv in existing terminal
                    local prompt_cmd =
                        'if [[ -n "$VIRTUAL_ENV" ]]; then venv_name=$(basename "$VIRTUAL_ENV"); if [[ "$PS1" != *"($venv_name)"* ]]; then if [[ -z "$_NVIM_ORIGINAL_PS1" ]]; then export _NVIM_ORIGINAL_PS1="$PS1"; fi; PS1="($venv_name) $_NVIM_ORIGINAL_PS1"; fi; elif [[ -n "$_NVIM_ORIGINAL_PS1" ]]; then PS1="$_NVIM_ORIGINAL_PS1"; fi'
                    local cmd = string.format(
                        "\x1b[2K\rexport VIRTUAL_ENV=\"%s\"; export PROMPT_COMMAND='%s'; clear\r",
                        venv_path,
                        prompt_cmd
                    )
                    vim.api.nvim_chan_send(chan, cmd)
                else
                    -- Deactivate venv in existing terminal
                    local cmd =
                        '\x1b[2K\runset VIRTUAL_ENV; if [[ -n "$_NVIM_ORIGINAL_PS1" ]]; then PS1="$_NVIM_ORIGINAL_PS1"; unset _NVIM_ORIGINAL_PS1; fi; unset PROMPT_COMMAND; clear\r'
                    vim.api.nvim_chan_send(chan, cmd)
                end
            end
        end
    end
end

local function update_terminals_cwd(new_cwd)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == "terminal" and vim.api.nvim_buf_is_loaded(buf) then
            local chan = vim.bo[buf].channel
            if chan and chan > 0 then
                local cmd = string.format('\x1b[2K\rcd "%s"; clear\r', new_cwd)
                vim.api.nvim_chan_send(chan, cmd)
            end
        end
    end
end

-- Auto-sync directory changes
vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
        update_terminals_cwd(vim.fn.getcwd())
    end,
})

-- Listen for venv activation events
vim.api.nvim_create_autocmd("User", {
    pattern = "VenvActivated",
    callback = function(ev)
        local data = ev.data or {}
        update_terminals_venv(data.venv_path, data.venv_name)
    end,
})

-- Listen for venv deactivation events
vim.api.nvim_create_autocmd("User", {
    pattern = "VenvDeactivated",
    callback = function()
        update_terminals_venv(nil, nil)
    end,
})

-- Public API (kept for backward compatibility)
M.update_venv = update_terminals_venv

return M
