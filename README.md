Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

Inspired by [LazyVim](https://github.com/LazyVim/LazyVim) and [AstroNvim](https://github.com/AstroNvim/AstroNvim)

### Features

- Lazy loading with [lazy.nvim](https://github.com/folke/lazy.nvim)
- Extensive use of [snacks.nvim](https://github.com/folke/snacks.nvim) including custom pickers
- Completions with [blink.cmp](https://github.com/Saghen/blink.cmp)
- Extensive use of [mini.icons](https://github.com/echasnovski/mini.icons) throughout the config for a cohesive appearance 
- Enhanced syntax highlighting with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and semantic highlighting
- [oil.nvim](https://github.com/stevearc/oil.nvim) for filesystem manipulation
- [trouble.nvim](https://github.com/folke/trouble.nvim) for everything wrong with your code
- [flash.nvim](https://github.com/folke/flash.nvim) for buffer navigation
- LSP integration with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- Realtime linting with [nvim-lint](https://github.com/mfussenegger/nvim-lint)
- Code formatting with [conform.nvim](https://github.com/stevearc/conform.nvim)
- Git integration with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) and [snacks.nvim](https://github.com/folke/snacks.nvim)'s lazygit
- LSP/tool management done with [mason.nvim](https://github.com/mason-org/mason.nvim) including a custom auto-installer using mason's registry directly
- Custom status column enhancements based on [LazyVim](https://github.com/LazyVim/LazyVim)'s status column
- Custom session manager with built-in session picker
- Custom floating terminal window module
- Custom indent guides module improving on current indent plugins within the ecosystem
- Custom statusline built with [heirline.nvim](https://github.com/rebelot/heirline.nvim) with a pretty path
- Custom chunk guides module based on [hlchunk.nvim](https://github.com/shellRaining/hlchunk.nvim)
- Custom breadcrumb navigation module based on [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim) and [nvim-navic](https://github.com/SmiteshP/nvim-navic)
- Custom virtual environment selector with built-in venv picker
- Python-specific indentation logic improving on GetPythonIndent()
- Unified code runner that supports multiple languages
- And much more

### Known Issues

- Tabs picker throwing an error when hovering over help buffers
- Sometimes opening whichkey has a delay even when on delay = 0
- Indent guides and winbar breadcrumbs may not be perfect yet

### Startup Time

```
Startuptime: 28.4ms

LazyStart 8.19ms
LazyDone  23ms (+14.81ms)
UIEnter   28.4ms (+5.4ms)
```

<!-- CODE_STATISTICS_START -->

### Code Statistics

```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Lua                             61            930            885           6135
Markdown                         2             19              4            152
JSON                             1              0              0             39
TOML                             1              0              0              3
-------------------------------------------------------------------------------
SUM:                            65            949            889           6329
-------------------------------------------------------------------------------
```
<!-- CODE_STATISTICS_END -->

<!-- PROJECT_STRUCTURE_START -->

### Project Structure

```
nvim
├── COMMANDS.md
├── init.lua
├── lazy-lock.json
├── lua
│   ├── core
│   │   ├── autocommands.lua
│   │   ├── init.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   ├── lsp_diagnostic.lua
│   │   └── options.lua
│   ├── custom
│   │   ├── extensions
│   │   │   ├── heirline_path.lua
│   │   │   ├── highlights.lua
│   │   │   ├── session_picker.lua
│   │   │   ├── tabs_picker.lua
│   │   │   └── venv_picker.lua
│   │   ├── indentation
│   │   │   ├── init.lua
│   │   │   └── python.lua
│   │   └── modules
│   │       ├── chunk_guides.lua
│   │       ├── code_runner.lua
│   │       ├── code_tester.lua
│   │       ├── eof_padding.lua
│   │       ├── floating_terminal.lua
│   │       ├── indent_guides.lua
│   │       ├── init.lua
│   │       ├── mode_number_color.lua
│   │       ├── session_manager.lua
│   │       ├── status_column.lua
│   │       ├── terminal_sync.lua
│   │       ├── venv_manager.lua
│   │       ├── winbar_breadcrumbs.lua
│   │       └── window_swapper.lua
│   └── plugins
│       ├── coding
│       │   ├── autopairs.lua
│       │   ├── dropbar.lua
│       │   ├── gitsigns.lua
│       │   ├── mini_ai.lua
│       │   ├── navic.lua
│       │   ├── surround.lua
│       │   ├── treesitter.lua
│       │   └── treesj.lua
│       ├── lsp_completion
│       │   ├── blink_cmp.lua
│       │   ├── conform.lua
│       │   ├── lazydev.lua
│       │   ├── lsp_config.lua
│       │   ├── luasnip.lua
│       │   ├── mason.lua
│       │   ├── nvim-dap.lua
│       │   ├── nvim-lint.lua
│       │   └── snippets
│       │       └── python.lua
│       ├── ui
│       │   ├── colorscheme.lua
│       │   ├── heirline.lua
│       │   ├── illuminate.lua
│       │   ├── mini_icons.lua
│       │   └── rainbow_delimiters.lua
│       └── utils
│           ├── flash.lua
│           ├── grug_far.lua
│           ├── guess_indent.lua
│           ├── indent_blankline.lua
│           ├── noice.lua
│           ├── oil.lua
│           ├── scrolleof.lua
│           ├── snacks.lua
│           ├── todo_comments.lua
│           ├── trouble.lua
│           └── whichkey.lua
└── README.md

13 directories, 64 files
```
<!-- PROJECT_STRUCTURE_END -->

### Screenshots

<img width="1568" height="867" alt="Screenshot 2025-08-11 174540" src="https://github.com/user-attachments/assets/432249b3-ffa5-4aee-9b28-7dde74a165c2" />
<img width="1568" height="867" alt="Screenshot 2025-08-11 174625" src="https://github.com/user-attachments/assets/19ff9db1-e07b-4142-8ef8-37554f4c0d77" />
<img width="1568" height="867" alt="Screenshot 2025-08-11 174703" src="https://github.com/user-attachments/assets/712aa371-1c54-4264-b0c2-f65d81af77a4" />
