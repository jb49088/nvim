
### Commands

- `:messages` — check recent messages
- `:checkhealth` — run health checks
- `:lua =vim.lsp.get_active_clients()` — see active LSPs
- `:tabdo echo "Tab " . tabpagenr() . ": local=" . getcwd(-1, 0) . " global=" . getcwd(-1, -1)` — list all tabs with their local and global working directories
- `:echo $VIRTUAL_ENV` — show the active Python virtual environment path
- `:set indentexpr?` — show the current indentation expression/function for the buffer
- `:lua vim.notify("This is a test message", vim.log.levels.INFO)` — show a notification popup
- `:Inspect` — see highlight under cursor
- `:InspectTree` — show the Treesitter syntax tree of the current buffer
- `:set shiftwidth?` — show current indent size
- `:noh` — clear search highlighting
- `:retab` — convert existing tabs/spaces to match current `expandtab` and `tabstop` settings
- `:version` — show Neovim version and compile info
- `:lua local ft=vim.bo.filetype; local tools={}; for _,s in ipairs(vim.lsp.get_clients({bufnr=0})) do table.insert(tools,s.name) end; local lint=require("lint"); for _,l in ipairs(lint.linters_by_ft[ft] or {}) do table.insert(tools,l) end; local conform=require("conform"); for _,f in ipairs(conform.list_formatters(0)) do table.insert(tools,f.name) end; print(vim.inspect(tools))` — show all active LSPs, linters, and formatters for the current buffer
- `:set scrolloff?` — show current scrolloff value
- `:echo len(getbufinfo())` — see buffer count
