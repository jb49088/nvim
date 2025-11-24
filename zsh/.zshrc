# ================================================================================
# =                                    .ZSHRC                                    =
# ================================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Initialize direnv
eval "$(direnv hook zsh)"

# Terminal title for zellij
precmd() {
    print -Pn "\e]0;%n@%m:%~\a"
}

# Automatically start zellij
eval "$(zellij setup --generate-auto-start zsh)"

# cd into dirs without typing cd
setopt autocd

# Suggest corrections for mistyped commands
setopt correct

# ================================================================================
# =                                    PROMPT                                    =
# ================================================================================

export VIRTUAL_ENV_DISABLE_PROMPT=1

setopt prompt_subst
PROMPT='%F{white}╭─%f${VIRTUAL_ENV:+($(basename "$VIRTUAL_ENV")) }%B%F{green}%n@%m%f%b %B%F{12}%~%f%b
%F{white}╰─$%f '

# ================================================================================
# =                                 COMPLETIONS                                  =
# ================================================================================

autoload -Uz compinit promptinit
compinit -C -d ~/.zcompdump
promptinit

# Complete in the middle of words
setopt completeinword

# Highlighting
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors 'di=38;5;12:fi=38;5;12:ln=38;5;12:ex=38;5;12'

# ================================================================================
# =                                   ALIASES                                    =
# ================================================================================

# General
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias weather='curl wttr.in'

# nvim
alias lvim='NVIM_APPNAME=nvim.lazy nvim'
alias avim='NVIM_APPNAME=nvim.astro nvim'
alias mvim='NVIM_APPNAME=nvim.mini nvim'

# Projects
alias alien_invasion='cd ~/python/projects/alien_invasion'
alias data_visualization='cd ~/python/projects/data_visualization/'
alias dotfiles='cd ~/dotfiles/'
alias learning_log='cd ~/python/projects/learning_log/'
alias infosec_forum='cd ~/python/projects/infosec_forum/'
alias pizzeria='cd ~/python/learning/demos/django/pizzeria/'
alias meal_planner='cd ~/python/learning/demos/django/meal_planner/'
alias neovim='cd ~/.config/nvim/'
alias raindrops='cd ~/python/learning/demos/pygame/raindrops/'
alias random_stars='cd ~/python/learning/demos/pygame/random_stars/'
alias rocket_game='cd ~/python/learning/demos/pygame/rocket_game/'
alias target_practice='cd ~/python/learning/demos/pygame/target_practice/'
alias watermelon_shooter='cd ~/python/learning/demos/pygame/watermelon_shooter/'
alias fish_tank='cd ~/python/projects/fish_tank/'

# Show project aliases
projects() {
  echo "Available projects:"
  alias | grep "cd ~" | sed "s/alias /  /" | sed "s/='cd /  -> /" | sed "s/'$//" | sort
}

# ================================================================================
# =                            ENVIRONMENT VARIABLES                             =
# ================================================================================

# General
export EDITOR=nvim

# Path
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/python/tools/:$PATH"

# Python
export PYTHONPATH="$HOME/python/modules:$PYTHONPATH"
export PYTHONBREAKPOINT=ipdb.set_trace

# Restic (credentials loaded from .zshrc.local)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# VcXsrv
export DISPLAY=$(ip route show default | awk '{print $3}'):0.0
export LIBGL_ALWAYS_INDIRECT=1

# ================================================================================
# =                                   KEYMAPS                                    =
# ================================================================================

bindkey '^R' history-incremental-search-backward

# ================================================================================
# =                                   HISTORY                                    =
# ================================================================================

# History file location
export HISTFILE=~/.zsh_history

# Increase history size
export HISTSIZE=100000
export SAVEHIST=100000

# Zsh history options
setopt HIST_IGNORE_DUPS      # Don't record duplicate commands
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt APPEND_HISTORY        # Append to history file
setopt SHARE_HISTORY         # Share history across all sessions
setopt INC_APPEND_HISTORY    # Write to history immediately

# ================================================================================
# =                                   PLUGINS                                    =
# ================================================================================

# git clone https://github.com/hlissner/zsh-autopair ~/.zsh/zsh-autopair
source ~/.zsh/zsh-autopair/autopair.zsh
