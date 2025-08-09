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
- Integrated code runner
- [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) with a custom venv picker
- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [trouble.nvim](https://github.com/folke/trouble.nvim)
- And much more

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
│   │   │   ├── tabs_picker.lua
│   │   │   └── venv_picker.lua
│   │   ├── indentation
│   │   │   ├── init.lua
│   │   │   └── python.lua
│   │   └── modules
│   │       ├── chunk_guides.lua
│   │       ├── code_runner.lua
│   │       ├── eof_padding.lua
│   │       ├── float_cycle.lua
│   │       ├── floating_terminal.lua
│   │       ├── indent_guides.lua
│   │       ├── init.lua
│   │       ├── mode_number_color.lua
│   │       ├── session_manager.lua
│   │       ├── status_column.lua
│   │       └── winbar_breadcrumbs.lua
│   └── plugins
│       ├── coding
│       │   ├── autopairs.lua
│       │   ├── autotag.lua
│       │   ├── gitsigns.lua
│       │   ├── mini_ai.lua
│       │   ├── surround.lua
│       │   └── treesitter.lua
│       ├── lsp_completion
│       │   ├── blink_cmp.lua
│       │   ├── conform.lua
│       │   ├── lazydev.lua
│       │   ├── lsp_config.lua
│       │   ├── luasnip.lua
│       │   ├── mason.lua
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
│           ├── noice.lua
│           ├── oil.lua
│           ├── snacks.lua
│           ├── todo_comments.lua
│           ├── trouble.lua
│           ├── venv_selector.lua
│           └── whichkey.lua
├── README.md
└── .stylua.toml
```

### Screenshots

<img width="1518" height="867" alt="Screenshot 2025-07-28 170955" src="https://github.com/user-attachments/assets/4f05a4bf-36f8-46f2-8202-e9ddc78af60a" />
<img width="1518" height="867" alt="Screenshot 2025-07-28 170847" src="https://github.com/user-attachments/assets/e8a6007e-1049-466e-b08a-a99f9b7506ad" />
<img width="1518" height="867" alt="Screenshot 2025-07-28 170931" src="https://github.com/user-attachments/assets/ce658363-67f0-41b2-9239-98f83d72f22a" />
