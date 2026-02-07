### dotfiles

Personal dotfiles and configuration management for my linux machines

<!-- CODE_STATISTICS_START -->

### Code Statistics

```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Lua                             60            673            593           4395
Markdown                         3             24              8            262
JSON                             2              0              0            244
TOML                             5              9              0            207
-------------------------------------------------------------------------------
SUM:                            70            706            601           5108
-------------------------------------------------------------------------------
```
<!-- CODE_STATISTICS_END -->

<!-- PROJECT_STRUCTURE_START -->

### Project Structure

```
dotfiles
├── direnv
│   └── direnv.toml
├── helix
│   ├── config.toml
│   ├── languages.toml
│   └── themes
│       └── astrodark.toml
├── nvim
│   ├── after
│   │   └── ftplugin
│   │       ├── css.lua
│   │       ├── htmldjango.lua
│   │       ├── html.lua
│   │       ├── javascript.lua
│   │       ├── json.lua
│   │       ├── kdl.lua
│   │       ├── lua.lua
│   │       ├── markdown.lua
│   │       ├── ps1.lua
│   │       ├── python.lua
│   │       ├── sh.lua
│   │       └── sql.lua
│   ├── COMMANDS.md
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lua
│   │   ├── core
│   │   │   ├── autocommands.lua
│   │   │   ├── diagnostics.lua
│   │   │   ├── init.lua
│   │   │   ├── keymaps.lua
│   │   │   ├── lazy.lua
│   │   │   └── options.lua
│   │   ├── custom
│   │   │   ├── extensions
│   │   │   │   ├── heirline_path.lua
│   │   │   │   ├── highlights.lua
│   │   │   │   └── tabs_picker.lua
│   │   │   ├── indentation
│   │   │   │   ├── init.lua
│   │   │   │   └── python.lua
│   │   │   └── modules
│   │   │       ├── code_debugger.lua
│   │   │       ├── code_runner.lua
│   │   │       ├── divider_generator.lua
│   │   │       ├── eof_padding.lua
│   │   │       ├── init.lua
│   │   │       ├── mode_number_color.lua
│   │   │       ├── status_column.lua
│   │   │       ├── winbar_breadcrumbs.lua
│   │   │       └── window_swapper.lua
│   │   └── plugins
│   │       ├── coding
│   │       │   ├── autotag.lua
│   │       │   ├── gitsigns.lua
│   │       │   ├── mini_ai.lua
│   │       │   ├── surround.lua
│   │       │   ├── treesitter.lua
│   │       │   ├── treesj.lua
│   │       │   └── ultimate-autopair.lua
│   │       ├── lsp_completion
│   │       │   ├── blink_cmp.lua
│   │       │   ├── conform.lua
│   │       │   ├── lazydev.lua
│   │       │   ├── lsp_config.lua
│   │       │   ├── mason.lua
│   │       │   └── nvim-lint.lua
│   │       ├── ui
│   │       │   ├── colorscheme.lua
│   │       │   ├── heirline.lua
│   │       │   ├── illuminate.lua
│   │       │   ├── mini_icons.lua
│   │       │   ├── nvim_highlight_colors.lua
│   │       │   ├── nvim_ufo.lua
│   │       │   └── rainbow_delimiters.lua
│   │       └── utils
│   │           ├── flash.lua
│   │           ├── guess_indent.lua
│   │           ├── oil.lua
│   │           ├── snacks.lua
│   │           ├── todo_comments.lua
│   │           ├── whichkey.lua
│   │           └── zellij_nav.lua
│   ├── README.md
│   └── snippets
│       └── python.json
├── README.md
├── sqlite
├── zellij
│   ├── config.kdl
│   └── themes
│       └── astrodark.kdl
└── zsh

23 directories, 71 files
```
<!-- PROJECT_STRUCTURE_END -->
