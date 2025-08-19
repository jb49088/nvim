Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

Inspired by [LazyVim](https://github.com/LazyVim/LazyVim) and [AstroNvim](https://github.com/AstroNvim/AstroNvim)

### Features

- Lazy loading with [lazy.nvim](https://github.com/folke/lazy.nvim)
- Extensive use of [snacks.nvim](https://github.com/folke/snacks.nvim) including custom pickers
- Custom statusline built with [heirline.nvim](https://github.com/rebelot/heirline.nvim) with a pretty path
- Completions with [blink.cmp](https://github.com/Saghen/blink.cmp)
- Extensive use of [mini.icons](https://github.com/echasnovski/mini.icons) throughout the config for a cohesive appearance 
- Enhanced syntax highlighting with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and semantic highlighting
- Session manager with a built-in session picker
- Floating terminal window
- Status column enhancements
- Python-specific indentation logic
- Indent guides module
- Chunk guides module
- Breadcrumb navigation module
- Unified code runner
- [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) with a custom venv picker
- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [trouble.nvim](https://github.com/folke/trouble.nvim)
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
Lua                             58            835            829           5798
Markdown                         1             17              4            126
JSON                             1              0              0             38
-------------------------------------------------------------------------------
SUM:                            60            852            833           5962
-------------------------------------------------------------------------------
```
<!-- CODE_STATISTICS_END -->

<!-- PROJECT_STRUCTURE_START -->

### Project Structure

```
nvim
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
│   │   │   └── tabs_picker.lua
│   │   ├── indentation
│   │   │   ├── init.lua
│   │   │   └── python.lua
│   │   └── modules
│   │       ├── chunk_guides.lua
│   │       ├── code_runner.lua
│   │       ├── eof_padding.lua
│   │       ├── floating_terminal.lua
│   │       ├── indent_guides.lua
│   │       ├── init.lua
│   │       ├── mode_number_color.lua
│   │       ├── session_manager.lua
│   │       ├── status_column.lua
│   │       ├── terminal_sync.lua
│   │       ├── venv_selector.lua
│   │       └── winbar_breadcrumbs.lua
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

13 directories, 60 files
```
<!-- PROJECT_STRUCTURE_END -->

### Screenshots

<img width="1568" height="867" alt="Screenshot 2025-08-11 174540" src="https://github.com/user-attachments/assets/432249b3-ffa5-4aee-9b28-7dde74a165c2" />
<img width="1568" height="867" alt="Screenshot 2025-08-11 174625" src="https://github.com/user-attachments/assets/19ff9db1-e07b-4142-8ef8-37554f4c0d77" />
<img width="1568" height="867" alt="Screenshot 2025-08-11 174703" src="https://github.com/user-attachments/assets/712aa371-1c54-4264-b0c2-f65d81af77a4" />
