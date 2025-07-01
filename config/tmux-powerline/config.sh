#!/usr/bin/env bash
# ~/.config/tmux-powerline/config.sh

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                            General Settings                                 │
# └─────────────────────────────────────────────────────────────────────────────┘

# enable/disable debug
export TMUX_POWERLINE_DEBUG_MODE_ENABLED="true"
# use powerline-patched symbols
export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

# name of your theme
export TMUX_POWERLINE_THEME="theme"
# allow overriding the shipped themes/segments
export TMUX_POWERLINE_DIR_USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/themes"
export TMUX_POWERLINE_DIR_USER_SEGMENTS="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/segments"

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                          Two-Line Status Configuration                      │
# └─────────────────────────────────────────────────────────────────────────────┘

# show two status lines:
#  0 → window list on top; left/right segments on bottom
#  1 → window list on bottom; left/right segments on top
export TMUX_POWERLINE_STATUS_VISIBILITY="2"
export TMUX_POWERLINE_WINDOW_STATUS_LINE=0

# justify the window-list line to the left
export TMUX_POWERLINE_STATUS_JUSTIFICATION="left"
# no extra separator between windows
export TMUX_POWERLINE_WINDOW_STATUS_SEPARATOR=""

# redraw interval in seconds
export TMUX_POWERLINE_STATUS_INTERVAL="1"

# how many characters allowed before truncation
export TMUX_POWERLINE_STATUS_LEFT_LENGTH="100"
export TMUX_POWERLINE_STATUS_RIGHT_LENGTH="0"

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                        Bottom Bar Segments Config                           │
# └─────────────────────────────────────────────────────────────────────────────┘

# battery.sh {
	# How to display battery remaining. Can be {percentage, cute, hearts}.
	export TMUX_POWERLINE_SEG_BATTERY_TYPE="percentage"
	# How may hearts to show if cute indicators are used.
	export TMUX_POWERLINE_SEG_BATTERY_NUM_HEARTS="5"
# }

# date.sh {
	# date(1) format for the date. If you don't, for some reason, like ISO 8601 format you might want to have "%D" or "%m/%d/%Y".
        export TMUX_POWERLINE_SEG_DATE_FORMAT="󰨳 %b-%d-%Y"
# }

# hostname.sh {
	# use short or long format for the hostname. can be {"short, long"}.
	export TMUX_POWERLINE_SEG_HOSTNAME_FORMAT="short"
# }

# lan_ip.sh {
	# Symbol for LAN IP.
	export TMUX_POWERLINE_SEG_LAN_IP_SYMBOL=" "
	# Symbol colour for LAN IP
	# export TMUX_POWERLINE_SEG_LAN_IP_SYMBOL_COLOUR="255"
# }

# pwd.sh {
	# Maximum length of output.
	export TMUX_POWERLINE_SEG_PWD_MAX_LEN="40"
# }

# time.sh {
	# date(1) format for the time. Americans might want to have "%I:%M %p".
	# Use TZ Identifier like "America/Los_Angeles"
	export TMUX_POWERLINE_SEG_TIME_FORMAT="%I:%M %p"
	export TMUX_POWERLINE_SEG_TIME_TZ="America/La_Paz"
# }

# tmux_session_info.sh {
	# Session info format to feed into the command: tmux display-message -p
	# For example, if FORMAT is '[ #S ]', the command is: tmux display-message -p '[ #S ]'
	export TMUX_POWERLINE_SEG_TMUX_SESSION_INFO_FORMAT="#S:#I.#P"
# }

# utc_time.sh {
	# date(1) format for the UTC time.
	export TMUX_POWERLINE_SEG_UTC_TIME_FORMAT="%H:%M %Z"
# }

# wan_ip.sh {
	# symbol for wan ip
	export TMUX_POWERLINE_SEG_WAN_IP_SYMBOL=" "
	# symbol colour for wan ip
	# export TMUX_POWERLINE_SEG_WAN_IP_SYMBOL_COLOUR="255"
# }

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                          Bottom-Bar Segments                                │
# └─────────────────────────────────────────────────────────────────────────────┘
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
  TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
    "tmux_session_info 148 234"
    "hostname           33  0"
    "lan_ip             208 0 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}"
    "wan_ip             84  0 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}"
    "pwd                99  255"
  )
fi

if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
  TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
    "battery            226 234"
    "time               240 255 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
    "utc_time           244 255 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
    "date               0   255"
  )
fi
