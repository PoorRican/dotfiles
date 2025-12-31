# 00-term.zsh - Terminal validation with Ghostty fallback
# Must run before other configs that depend on valid TERM

# Store original TERM for reference (e.g., tmux can check this)
export TERM_ORIGINAL="${TERM_ORIGINAL:-$TERM}"

# Check if terminfo exists for current TERM
if ! infocmp "$TERM" >/dev/null 2>&1; then
    # Terminfo missing - fallback to xterm-256color
    export TERM="xterm-256color"
fi
