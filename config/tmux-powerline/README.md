# 🔋 Tmux Powerline

Two-line tmux status bar (`erikw/tmux-powerline`, installed via TPM). Needs a Nerd/Powerline font; colors inherit from your Base16 scheme.

- **Top line:** window list.
- **Bottom line:** session info · hostname · LAN IP · WAN IP · cwd · battery · local time · UTC time · date.

## Files

| File | Purpose |
|------|---------|
| `config.sh` | Segment list + settings |
| `themes/theme.sh` | Colors and separators |

## Segments

| Side | Segments |
|------|----------|
| Left | session `#S:#I.#P` · hostname (short) · LAN IP · WAN IP · cwd (max 40 chars) |
| Right | battery % · local time (`America/La_Paz`) · UTC time · date |

Layout: two-line status, window list top/left-justified, left length 100, update interval 1s.

## Customization (`config.sh`)

Segments are `"name fg bg"` entries in `TMUX_POWERLINE_LEFT_STATUS_SEGMENTS`. Remove unused ones (e.g. the IP segments) to speed updates. Common knobs:

```bash
export TMUX_POWERLINE_SEG_PWD_MAX_LEN="40"
export TMUX_POWERLINE_SEG_HOSTNAME_FORMAT="short"
export TMUX_POWERLINE_SEG_TIME_FORMAT="%I:%M %p"
export TMUX_POWERLINE_SEG_TIME_TZ="America/La_Paz"
export TMUX_POWERLINE_SEG_DATE_FORMAT="󰨳 %b-%d-%Y"
export TMUX_POWERLINE_STATUS_INTERVAL="1"   # raise to save battery
```

Color codes used: `0` black · `33` blue · `84` cyan · `99` purple · `148` yellow · `208` orange · `226` bright-yellow · `234`/`240`/`244` grays · `255` white.

## Troubleshooting

- **Separators show as boxes/`?`:** install a Nerd Font (`brew install --cask font-jetbrains-mono-nerd-font`) and set it in your terminal.
- **Slow:** raise `TMUX_POWERLINE_STATUS_INTERVAL` or drop segments.
- **Colors off:** `echo $TERM` should be `screen-256color` inside tmux.
- **Debug:** `export TMUX_POWERLINE_DEBUG_MODE_ENABLED="true"` then `tail -f ~/.tmux-powerline.log`.
