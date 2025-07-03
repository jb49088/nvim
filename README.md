Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)

Inspired by [LazyVim](https://github.com/LazyVim/LazyVim)

#### Features

- Lazy loading with [lazy.nvim](https://github.com/folke/lazy.nvim)
- [AstroNvim's](https://github.com/AstroNvim/AstroNvim) colorscheme [astrotheme](https://github.com/AstroNvim/astrotheme)
- Custom [lualine](https://github.com/nvim-lualine/lualine.nvim) including [lualine-pretty-path](https://github.com/bwpge/lualine-pretty-path/)
- Extensive use of [snacks.nvim](https://github.com/folke/snacks.nvim) including custom pickers
- [oil.nvim](https://github.com/stevearc/oil.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- [auto-session](https://github.com/rmagatti/auto-session)
- [trouble.nvim](https://github.com/folke/trouble.nvim)
- And much more

#### Project Structure

nvim
├── init.lua
├── lazy-lock.json
├── lua
│   ├── core
│   │   ├── autocommands.lua
│   │   ├── custom_functions.lua
│   │   ├── highlights.lua
│   │   ├── init.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   ├── lsp_diagnostic.lua
│   │   └── options.lua
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
│       │   ├── illuminate.lua
│       │   ├── lualine.lua
│       │   ├── mini_icons.lua
│       │   └── noice.lua
│       └── utils
│           ├── auto_session.lua
│           ├── flash.lua
│           ├── fzf.lua
│           ├── grug-far.lua
│           ├── guess_indent.lua
│           ├── oil.lua
│           ├── rainbow_delimiters.lua
│           ├── scrolleof.lua
│           ├── snacks.lua
│           ├── startuptime.lua
│           ├── todo_comments.lua
│           ├── toggleterm.lua
│           ├── trouble.lua
│           └── whichkey.lua
└── README.md

#### Screenshots

![Screenshot 2025-07-02 161952](https://github.com/user-attachments/assets/a28dbcf4-3fbc-41e7-a3ea-992854801fc5)
![Screenshot 2025-07-02 161902](https://github.com/user-attachments/assets/09d3ad66-133b-4835-8424-2f14dfe7db26)
