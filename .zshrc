
# zprof used to show init proformance
# Maybe some network requests may cause the shell to freeze.

# zmodload zsh/zprof

# set -x

# eval "$(starship init zsh)"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugin configs
VSCODE=code

plugins=(
  rbenv
  argocd
  git
  copybuffer
  copypath
  copyfile
  cp
  encode64
  extract
  nmap
  fzf
  vscode
  vi-mode
  kubectl
  fzf-tab
  zsh-syntax-highlighting
  alias-finder
  aliases
  zoxide poetry
  podman
)

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source $ZSH/oh-my-zsh.sh

# User configuration

export LANG=en_US.UTF-8
export EDITOR='hx'
export WORKSPACE="$HOME/Workspace"
export DISABLE_TELEMETRY=1

export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY

# Aliases
alias gcan='git commit --amend --no-verify'
alias gcann='git commit --amend --no-verify --no-edit'
alias zshrc="$EDITOR ~/.zshrc"
alias hammerrc="$EDITOR ~/.hammerspoon/init.lua"
alias ghosttyrc="$EDITOR ~/.config/ghostty/config"
alias hxrc="$EDITOR ~/.config/helix/config.toml"
alias zellijrc="$EDITOR ~/.config/zellij/config.kdl"
alias less="bat"
alias c="clear"
alias rm="trash"
alias p="podman"
alias psc="podman system connection"
alias pc="podman-compose"
alias bb="bun --bun"

alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
alias luamake="/Users/wangjie/Workspace/wangjie/luamake/luamake"

# homebrew
export HOMEBREW_NO_AUTO_UPDATE=1

if [ "$(arch)" = "arm64" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# GNU utils
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

export PATH="$PATH:$HOME/.cargo/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.yarn/bin"

export PATH="$PATH:$HOME/Workspace/flutter/bin"

export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export ANDROID_AVD_HOME="$HOME/.android/avd"

export PATH=/usr/local/bin:$PATH
export PATH="/opt/homebrew/bin:$PATH"

eval "$(mise activate zsh)"
eval "$(pay-respects zsh --alias)"
eval "$(atuin init zsh --disable-up-arrow)"


# source /Users/wangjie/.rvm/scripts/rvm
export PATH=/usr/local/smlnj/bin:"$PATH"

export PATH="/usr/local/opt/llvm/bin:$PATH"

# mono
export PATH="$PATH:/Library/Frameworks/Mono.framework/Versions/Current/Commands"

# bob
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

export PATH="/Users/wangjie/.bun/bin:$PATH"

[ -f "/Users/wangjie/.ghcup/env" ] && source "/Users/wangjie/.ghcup/env" # ghcup-env


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pnpm
export PNPM_HOME="/Users/wangjie/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# >>> forge initialize >>>
# !! Contents within this block are managed by 'forge zsh setup' !!
# !! Do not edit manually - changes will be overwritten !!

# Add required zsh plugins if not already present
if [[ ! " ${plugins[@]} " =~ " zsh-autosuggestions " ]]; then
    plugins+=(zsh-autosuggestions)
fi
if [[ ! " ${plugins[@]} " =~ " zsh-syntax-highlighting " ]]; then
    plugins+=(zsh-syntax-highlighting)
fi

# Load forge shell plugin (commands, completions, keybindings) if not already loaded
if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then
    eval "$(forge zsh plugin)"
fi

# Load forge shell theme (prompt with AI context) if not already loaded
if [[ -z "$_FORGE_THEME_LOADED" ]]; then
    eval "$(forge zsh theme)"
fi
# <<< forge initialize <<<

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# zprof
