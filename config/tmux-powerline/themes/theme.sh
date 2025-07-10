#!/usr/bin/env bash


# Separator Characters
# ───────────────────────────────────────────────────
if patched_font_in_use; then
    TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=" "
    TMUX_POWERLINE_SEPARATOR_LEFT_THIN=" "
    TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=" "
    TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=" "
else
    TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="◀"
    TMUX_POWERLINE_SEPARATOR_LEFT_THIN="❮"
    TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"
    TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="❯"
fi


# Inherit base16 colors
# ───────────────────────────────────────────────────

# use the terminal’s default background/foreground (your base16 palette)
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-'terminal'}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-'terminal'}


# Window-List Line (Top Bar)
# ───────────────────────────────────────────────────

# active window entry: use reverse video of the inactive style
TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
  "#[fg=$TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR,bg=$TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR]"   # swap colors
  "#[reverse]"                                                                                   # invert
  "  #I:#W  "                                                                                    # padded "*1:main"
  "#[noreverse]"                                                                                 # back to normal
)

# inactive window entry: default fg/bg, padded
TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
  "#[fg=$TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR,bg=$TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR]"
  "  #I:#W  "
)

# ensure the whole line uses “regular” style
TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
  "$(format regular)"
)

