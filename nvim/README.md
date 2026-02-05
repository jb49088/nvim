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
- Custom statusline built with [heirline.nvim](https://github.com/rebelot/heirline.nvim) with a pretty path
- Custom Python indentation with treesitter-aware bracket detection
- And much more

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
Lua                             61            679            604           4493
JSON                             2              0              0            245
Markdown                         2             16              4            148
TOML                             1              0              0              3
-------------------------------------------------------------------------------
SUM:                            66            695            608           4889
-------------------------------------------------------------------------------
```
<!-- CODE_STATISTICS_END -->

<!-- PROJECT_STRUCTURE_START -->

### Project Structure

```
nvim
├── after
│   └── ftplugin
│       ├── css.lua
│       ├── htmldjango.lua
│       ├── html.lua
│       ├── javascript.lua
│       ├── json.lua
│       ├── kdl.lua
│       ├── lua.lua
│       ├── markdown.lua
│       ├── ps1.lua
│       ├── python.lua
│       ├── sh.lua
│       └── sql.lua
├── COMMANDS.md
├── init.lua
├── lazy-lock.json
├── lua
│   ├── core
│   │   ├── autocommands.lua
│   │   ├── diagnostics.lua
│   │   ├── init.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   ├── custom
│   │   ├── extensions
│   │   │   ├── heirline_path.lua
│   │   │   ├── highlights.lua
│   │   │   └── tabs_picker.lua
│   │   ├── indentation
│   │   │   ├── init.lua
│   │   │   └── python.lua
│   │   └── modules
│   │       ├── code_debugger.lua
│   │       ├── code_runner.lua
│   │       ├── divider_generator.lua
│   │       ├── eof_padding.lua
│   │       ├── init.lua
│   │       ├── mode_number_color.lua
│   │       ├── status_column.lua
│   │       ├── winbar_breadcrumbs.lua
│   │       └── window_swapper.lua
│   └── plugins
│       ├── coding
│       │   ├── autotag.lua
│       │   ├── gitsigns.lua
│       │   ├── mini_ai.lua
│       │   ├── surround.lua
│       │   ├── treesitter.lua
│       │   ├── treesj.lua
│       │   └── ultimate-autopair.lua
│       ├── lsp_completion
│       │   ├── blink_cmp.lua
│       │   ├── conform.lua
│       │   ├── lazydev.lua
│       │   ├── lsp_config.lua
│       │   ├── mason.lua
│       │   └── nvim-lint.lua
│       ├── ui
│       │   ├── colorscheme.lua
│       │   ├── heirline.lua
│       │   ├── illuminate.lua
│       │   ├── mini_icons.lua
│       │   ├── nvim_highlight_colors.lua
│       │   ├── nvim_ufo.lua
│       │   └── rainbow_delimiters.lua
│       └── utils
│           ├── flash.lua
│           ├── guess_indent.lua
│           ├── noice.lua
│           ├── oil.lua
│           ├── snacks.lua
│           ├── todo_comments.lua
│           ├── whichkey.lua
│           └── zellij_nav.lua
├── README.md
└── snippets
    └── python.json

15 directories, 65 files
```
<!-- PROJECT_STRUCTURE_END -->

### Screenshots

<img width="1568" height="888" alt="Screenshot 2025-11-11 070410" src="https://github.com/user-attachments/assets/d72689b3-0bba-46b0-9736-0ad070111b98" />
<img width="1568" height="888" alt="Screenshot 2025-11-11 065729" src="https://github.com/user-attachments/assets/b2bd1511-0895-413e-9aae-2e512818474f" />
<img width="1568" height="888" alt="Screenshot 2025-11-11 065954" src="https://github.com/user-attachments/assets/f3a846b0-aeab-493a-9c79-f8e72dc906ee" />
