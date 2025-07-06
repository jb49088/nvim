Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

Inspired by [LazyVim](https://github.com/LazyVim/LazyVim) and [AstroNvim](https://github.com/AstroNvim/AstroNvim)

#### Features

- Lazy loading with [lazy.nvim](https://github.com/folke/lazy.nvim)
- Extensive use of [snacks.nvim](https://github.com/folke/snacks.nvim) including custom pickers
- [lualine](https://github.com/nvim-lualine/lualine.nvim) with custom components
- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- [auto-session](https://github.com/rmagatti/auto-session)
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
│   │   │   ├── highlights.lua
│   │   │   ├── lualine_path.lua
│   │   │   └── tabs_picker.lua
│   │   └── standalone
│   │       ├── init.lua
│   │       └── mode_line_color.lua
│   └── plugins
│       ├── coding
│       │   ├── autotag.lua
│       │   ├── gitsigns.lua
│       │   ├── mini_ai.lua
│       │   ├── mini_pairs.lua
│       │   ├── surround.lua
│       │   └── treesitter.lua
│       ├── lsp_completion
│       │   ├── blink_cmp.lua
│       │   ├── conform.lua
│       │   ├── lazydev.lua
│       │   ├── lsp_config.lua
│       │   └── mason.lua
│       ├── ui
│       │   ├── colorscheme.lua
│       │   ├── fidget.lua
│       │   ├── illuminate.lua
│       │   ├── lualine.lua
│       │   ├── mini_icons.lua
│       │   └── rainbow_delimiters.lua
│       └── utils
│           ├── auto_session.lua
│           ├── flash.lua
│           ├── grug_far.lua
│           ├── guess_indent.lua
│           ├── oil.lua
│           ├── scrolleof.lua
│           ├── snacks.lua
│           ├── todo_comments.lua
│           ├── toggleterm.lua
│           ├── trouble.lua
│           └── whichkey.lua
├── README.md
└── .stylua.toml
```

#### Screenshots

![Screenshot 2025-07-04 225148](https://github.com/user-attachments/assets/b935e399-46ae-4f75-ba88-212cb923c95b)
![Screenshot 2025-07-04 225346](https://github.com/user-attachments/assets/8db5822a-d8d8-400e-b387-ce834b813502)

