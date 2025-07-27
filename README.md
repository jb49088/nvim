Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

Inspired by [LazyVim](https://github.com/LazyVim/LazyVim) and [AstroNvim](https://github.com/AstroNvim/AstroNvim)

#### Features

- Lazy loading with [lazy.nvim](https://github.com/folke/lazy.nvim)
- Extensive use of [snacks.nvim](https://github.com/folke/snacks.nvim) including custom pickers
- Custom statusline built with [heirline.nvim](https://github.com/rebelot/heirline.nvim) with a pretty path
- Completions with [blink.cmp](https://github.com/Saghen/blink.cmp)
- Extensive use of [mini.icons](https://github.com/echasnovski/mini.icons) throughout the config for a cohesive appearance 
- Enhanced syntax highlighting with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and semantic highlighting
- [auto-session](https://github.com/rmagatti/auto-session) with a custom session picker
- [venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim) with a custom venv picker
- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- [trouble.nvim](https://github.com/folke/trouble.nvim)
- And much more

#### Project Structure

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
│   │   ├── integrations
│   │   │   ├── heirline_breadcrumbs.lua
│   │   │   ├── heirline_path.lua
│   │   │   ├── highlights.lua
│   │   │   ├── lualine_path.lua
│   │   │   ├── mode_heirline_color.lua
│   │   │   ├── session_picker.lua
│   │   │   ├── tabs_picker.lua
│   │   │   └── venv_picker.lua
│   │   └── modules
│   │       ├── eof_padding.lua
│   │       ├── float_cycle.lua
│   │       ├── floating_terminal.lua
│   │       ├── init.lua
│   │       ├── mode_number_color.lua
│   │       └── run.lua
│   └── plugins
│       ├── coding
│       │   ├── autotag.lua
│       │   ├── dropbar.lua
│       │   ├── gitsigns.lua
│       │   ├── mini_ai.lua
│       │   ├── mini_pairs.lua
│       │   ├── navic.lua
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
│       │   ├── devicons.lua
│       │   ├── heirline.lua
│       │   ├── illuminate.lua
│       │   ├── lualine.lua
│       │   ├── mini_icons.lua
│       │   └── rainbow_delimiters.lua
│       └── utils
│           ├── auto_session.lua
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

#### Screenshots

<img width="1558" height="867" alt="Screenshot 2025-07-17 233446" src="https://github.com/user-attachments/assets/7f86be83-d714-4b01-8ddf-d65b968cf374" />
<img width="1558" height="867" alt="Screenshot 2025-07-17 233344" src="https://github.com/user-attachments/assets/d84666ed-0b35-4f9c-a05b-f7f94f957552" />

