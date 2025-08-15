#!/bin/bash

# ═══════════════════════════════════════════════════
# Rofi Power Menu Script
# Simple power management menu for Hyprland
# ═══════════════════════════════════════════════════

# Menu options
options=" Lock\n Logout\n Suspend\n⏻ Shutdown\n Reboot"

# Show menu and capture selection
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -theme-str 'window {width: 300px;} listview {lines: 5;}')

case $chosen in
    " Lock")
        swaylock-effects
        ;;
    " Logout")
        # For Hyprland
        hyprctl dispatch exit
        ;;
    " Suspend")
        systemctl suspend
        ;;
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    " Reboot")
        systemctl reboot
        ;;
    *)
        # Do nothing if canceled
        ;;
esac