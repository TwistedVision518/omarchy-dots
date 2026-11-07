# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# Experiential gateway & Claude configuration
export EXPLABS_API_KEY="xpl_92d4b16af41c3efc2271a027c4ec9bac5f8f441e"
unset ANTHROPIC_API_KEY
export ANTHROPIC_AUTH_TOKEN="$EXPLABS_API_KEY"
export ANTHROPIC_BASE_URL="https://api.experientiallabs.ai"
export ANTHROPIC_MODEL="claude-opus-5.5"
export ANTHROPIC_CUSTOM_MODEL_OPTION="gpt-6-luna"
export ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="GPT-6 Luna"
export ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION="GPT-6 Luna via Experiential"
export OPENAI_BASE_URL="https://api.experientiallabs.ai/v1"
export OPENAI_API_KEY="$EXPLABS_API_KEY"

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

copilot-claude() {
  env COPILOT_PROVIDER_BASE_URL="http://127.0.0.1:8787/v1" \
    COPILOT_PROVIDER_TYPE="openai" \
    COPILOT_PROVIDER_API_KEY="$EXPLABS_API_KEY" \
    COPILOT_PROVIDER_WIRE_API="completions" \
    COPILOT_PROVIDER_MODEL_ID="claude-opus-5.5" \
    COPILOT_PROVIDER_WIRE_MODEL="claude-opus-5.5" \
    COPILOT_MODEL="claude-opus-5.5" \
    copilot "$@"
}

copilot-luna() {
  env COPILOT_PROVIDER_BASE_URL="http://127.0.0.1:8787/v1" \
    COPILOT_PROVIDER_TYPE="openai" \
    COPILOT_PROVIDER_API_KEY="$EXPLABS_API_KEY" \
    COPILOT_PROVIDER_WIRE_API="completions" \
    COPILOT_PROVIDER_MODEL_ID="gpt-6-luna" \
    COPILOT_PROVIDER_WIRE_MODEL="gpt-6-luna" \
    COPILOT_MODEL="gpt-6-luna" \
    copilot "$@"
}

# All the default Omarchy aliases and functions
source "$OMARCHY_PATH/default/bash/rc"

# Pick a fresh Pokémon from Poketex's bundled art for each terminal.
(
  shopt -s nullglob
  pokemon_art=(/usr/share/poketex/colorscripts/small/regular/*)
  if ((${#pokemon_art[@]})); then
    pokemon_logo=$(printf '%s\n' "${pokemon_art[@]}" | shuf -n 1)
    fastfetch --logo-type file-raw --logo "$pokemon_logo"
  else
    fastfetch
  fi
)

. "$HOME/.local/share/../bin/env"


export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1

# Programmable completion for commands and their options.
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

# Live command-line syntax highlighting and richer editing.
if [[ -r "$HOME/.local/share/blesh/ble.sh" ]]; then
  source "$HOME/.local/share/blesh/ble.sh" --attach=none
fi

# Fuzzy history/file completion with Ctrl-R, Alt-C, and Ctrl-T.
if [[ -r /usr/share/fzf/key-bindings.bash ]]; then
  source /usr/share/fzf/key-bindings.bash
fi
if [[ -r /usr/share/fzf/completion.bash ]]; then
  source /usr/share/fzf/completion.bash
fi

# A richer prompt with directory, Git branch, and repository status.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if [[ ${BLE_VERSION-} ]]; then
  ble-attach
fi


# Added by Antigravity CLI installer
export PATH="/home/twistedvis/.local/bin:$PATH"
