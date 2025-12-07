# System & Tools Keybindings Cheat Sheet

## 🖥️  Hammerspoon (System-wide)

| Keybinding | Action |
|------------|--------|
| `Alt + Space` | Focus/Launch Kitty terminal (hide if already focused) |

---

## 🖥️  Tmux (Prefix: `)

### Window Management
| Keybinding | Action | Location |
|------------|--------|----------|
| `` ` `` | Send literal backtick | tmux.conf:4 |
| `, / .` | Previous/Next window | tmux.conf:8-9 |
| `H / L` | Previous/Next window | tmux.conf:10-11 |
| `u / i` | Previous/Next window | tmux.conf:12-13 |
| `m` | Move window (prompt for target) | tmux.conf:14 |
| `n` | Rename window | tmux.conf:29 |
| `N` | Rename session | tmux.conf:30 |
| `X` | Kill window | tmux.conf:32 |

### Pane Management
| Keybinding | Action | Location |
|------------|--------|----------|
| `h / j / k / l` | Select pane (vim-like) | tmux.conf:15-18 |
| `\` | Split horizontally | tmux.conf:19 |
| `-` | Split vertically | tmux.conf:20 |
| `o` | Rotate panes | tmux.conf:21 |
| `x` | Kill pane | tmux.conf:31 |

### Pane Resizing
| Keybinding | Action | Location |
|------------|--------|----------|
| `Left/Right` | Resize pane left/right by 5 | tmux.conf:22-23 |
| `Up/Down` | Resize pane up/down by 5 | tmux.conf:24-25 |

### Layout Management
| Keybinding | Action | Location |
|------------|--------|----------|
| `v` | Even horizontal layout | tmux.conf:26 |
| `b` | Even vertical layout | tmux.conf:27 |
| `t` | Tiled layout | tmux.conf:28 |

### Utility
| Keybinding | Action | Location |
|------------|--------|----------|
| `Space` | Command prompt | tmux.conf:33 |
| `r` | Reload tmux config | tmux.conf:34 |

### Tmux Plugin Features
- **tmux-yank**: Copy mode with `y`
- **tmux-fingers**: Hint mode for easy text selection
- **tmux-resurrect**: Save/restore sessions automatically
- **tmux-continuum**: Auto-save sessions
- **tmux-mighty-scroll**: Enhanced scrolling
- **tmux-better-mouse-mode**: Improved mouse support

---

## 🐚 Shell Aliases & Functions

### Quick Navigation
| Command | Action | Location |
|---------|--------|----------|
| `c / cl` | Clear screen | bash_profile_aliases:5-6 |
| `..` | Go to parent directory | bash_profile_aliases:42 |
| `...` | Go to previous directory | bash_profile_aliases:39 |
| `ff [n]` / `up [n]` | Go up n directories | bash_profile_functions:13-25 |

### Directory Shortcuts
| Command | Action | Location |
|---------|--------|----------|
| `cdv` | Go to vim directory | bash_profile_aliases:45 |
| `cd.` | Go to dotfiles directory | bash_profile_aliases:48 |
| `cdd` | Go to Desktop | bash_profile_aliases:51 |
| `cdc` | Go to Cave (rclone mount) | bash_profile_aliases:54 |
| `cdp` | Go to Projects | bash_profile_aliases:59 |
| `cds` | Go to Scratches | bash_profile_aliases:63 |
| `cave` | Open Cave in Finder (if mounted) | bash_profile_aliases:57 |

### File Operations
| Command | Action | Location |
|---------|--------|----------|
| `l / ll` | Long listing | bash_profile_aliases:24-25 |
| `la` | Long listing with hidden files | bash_profile_aliases:21 |
| `lh` | Human readable long listing | bash_profile_aliases:28 |
| `lah / lha` | Human readable with hidden | bash_profile_aliases:31-32 |
| `l1 / la1` | Single column listing | bash_profile_aliases:35-36 |
| `rmd` | Remove directory recursively | bash_profile_aliases:18 |
| `t` | Touch (create file) | bash_profile_aliases:66 |

### Editing
| Command | Action | Location |
|---------|--------|----------|
| `v / nv / av` | Open Neovim | bash_profile_aliases:13-15 |
| `vb` | Edit bash_profile | bash_profile_aliases:75 |
| `vbf` | Edit bash functions | bash_profile_aliases:78 |
| `vba` | Edit bash aliases | bash_profile_aliases:90 |
| `vbt` | Edit bash tools | bash_profile_aliases:81 |
| `vbg` | Edit bash git config | bash_profile_aliases:84 |
| `vbl` | Edit bash local config | bash_profile_aliases:87 |
| `vt` | Edit tmux config | bash_profile_aliases:100 |
| `vnv / nvc` | Edit nvim config | bash_profile_aliases:96-97 |
| `vk` | Edit kitty config | bash_profile_aliases:93 |
| `vg` | Edit .gitconfig | bash_profile_aliases:103 |
| `vetc` | Edit /etc/hosts | bash_profile_aliases:106 |

### Clipboard
| Command | Action | Location |
|---------|--------|----------|
| `pbc` | Copy to clipboard (pbcopy) | bash_profile_aliases:9 |
| `pbp` | Paste from clipboard | bash_profile_aliases:10 |
| `cwd` | Copy current directory path | bash_profile_aliases:63 |
| `lcp` | Linux clipboard copy (xclip) | bash_profile_aliases:121 |

### Tmux
| Command | Action | Location |
|---------|--------|----------|
| `tm` | Start tmux | bash_profile_aliases:69 |
| `tml` | List tmux sessions | bash_profile_aliases:70 |
| `tma` | Attach to tmux session | bash_profile_aliases:71 |
| `tmk` | Kill tmux session | bash_profile_aliases:72 |

### Directory Bookmarks
| Command | Action | Location |
|---------|--------|----------|
| `mark <name>` | Bookmark current directory | bash_profile_functions:50-52 |
| `unmark <name>` | Remove bookmark | bash_profile_functions:59-61 |
| `jump <name>` / `j <name>` | Jump to bookmark | bash_profile_functions:70-72 |
| `marks` | List all bookmarks | bash_profile_functions:79-81 |

### System Utilities
| Command | Action | Location |
|---------|--------|----------|
| `sb` | Source bash profile | bash_profile_aliases:112 |
| `flush` | Flush DNS cache | bash_profile_aliases:115 |
| `toggle_hidden` | Toggle hidden files in Finder | bash_profile_functions:32-43 |
| `npms` | npm in silent mode | bash_profile_aliases:118 |
| `dcp` | docker compose | bash_profile_aliases:124 |

---

## 📋 Git Aliases & Functions

### Basic Git Operations
| Command | Action | Location |
|---------|--------|----------|
| `gs` | git status | bash_profile_git:18 |
| `ga` | git add | bash_profile_git:21 |
| `gall` | git add --all | bash_profile_git:42 |
| `gau` | git add -u | bash_profile_git:45 |
| `gap` | git add -p | bash_profile_git:48 |
| `gcomm` | git commit -m | bash_profile_git:54 |
| `gam` | git commit --amend | bash_profile_git:66 |
| `gamn` | git commit --amend --no-edit | bash_profile_git:69 |

### Branch Management
| Command | Action | Location |
|---------|--------|----------|
| `gb` | git branch | bash_profile_git:60 |
| `gco` | git checkout | bash_profile_git:51 |
| `gcb` | git checkout -b | bash_profile_git:57 |
| `gbcp` | Copy current branch name | bash_profile_git:63 |
| `gcg <pattern>` | Checkout first branch matching pattern | bash_profile_git:107-110 |
| `gcrb <name>` | Checkout new remote-run/ branch | bash_profile_git:114-116 |

### Remote Operations
| Command | Action | Location |
|---------|--------|----------|
| `gp` | git pull | bash_profile_git:30 |
| `gpr` | git pull --rebase | bash_profile_git:33 |
| `gf` | git fetch | bash_profile_git:36 |
| `gpush [args]` | Push current branch to origin | bash_profile_git:119-126 |
| `gbu` | Set upstream for current branch | bash_profile_git:101-104 |

### Diff & Log
| Command | Action | Location |
|---------|--------|----------|
| `gd` | git diff | bash_profile_git:72 |
| `gds` | git diff --staged | bash_profile_git:78 |
| `gfd` | Show files changed in last commit | bash_profile_git:75 |
| `gl` | git log | bash_profile_git:39 |
| `glog` | git plog (pretty log) | bash_profile_git:81 |
| `gcsha` | Show current commit SHA | bash_profile_git:89 |

### Reset Operations
| Command | Action | Location |
|---------|--------|----------|
| `gr` | git reset | bash_profile_git:24 |
| `grh` | git reset --hard | bash_profile_git:27 |

### Advanced Functions
| Command | Action | Location |
|---------|--------|----------|
| `gup <message>` | Commit with message and push | bash_profile_git:129-132 |
| `roob [source_branch]` | Rebase current branch on source | bash_profile_git:135-142 |

### Submodules
| Command | Action | Location |
|---------|--------|----------|
| `gsmu` | Update all submodules | bash_profile_git:84 |
| `gsmi` | Initialize submodules recursively | bash_profile_git:87 |

### Branch Comparison
| Command | Action | Location |
|---------|--------|----------|
| `rc-diff` | Show commits between master/development | bash_profile_git:91 |
| `merges-diff` | Show merges between master/development | bash_profile_git:93 |

---

## 💡 Tips

- **Tmux prefix key**: `` ` `` (backtick)
- **Directory bookmarks**: Use `mark`, `jump`/`j`, and `marks` for quick navigation
- **Git workflow**: Common pattern is `gs` → `ga` → `gcomm` → `gpush`
- **Quick editing**: Use `v*` aliases to quickly edit configs (e.g., `vt` for tmux, `vnv` for nvim)
- **Fast directory navigation**: Use `ff [n]` to go up multiple directories at once