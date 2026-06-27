# 🐚 Bash Configuration

Customized bash setup — aliases, functions, git workflow, and tool integration.

## Quick Start

```bash
ln -sf ~/.dotfiles/config/bash/bash_profile ~/.bash_profile
source ~/.bash_profile   # or: sb
```

## File Structure

| File | Purpose |
|------|---------|
| `bash_profile` | Main profile; sources the others |
| `bash_profile_aliases` | Command aliases |
| `bash_profile_functions` | Custom functions |
| `bash_profile_git` | Git aliases and functions |
| `bash_profile_tools` | Tool integrations (nvm, pyenv, etc.) |
| `bash_profile_ssh` | SSH agent configuration |
| `bash_profile_local` | Machine-specific settings (not in git) |

## Core Settings

- **Prompt:** custom PS1 (directory + git branch), truecolor, Base16 integration.
- **History:** eternal (no size limit), timestamped, written immediately, at `~/.bash_eternal_history`.
- **Shell:** vi mode (`set -o vi`), `globstar`, `histappend`, `cmdhist`.

## Aliases

### Essential
| Alias | Command |
|-------|---------|
| `c`, `cl` | `clear` |
| `v` / `nv`, `av` | `vim` / `nvim` |
| `t` | `touch` |
| `sb` | `source ~/.bash_profile` |

### Files
| Alias | Command |
|-------|---------|
| `l`, `ll` | `ls -l` |
| `la` | `ls -la` |
| `lh` | `ls -lh` |
| `lah`, `lha` | `ls -lah` |
| `l1`, `la1` | `ls -lh1`, `ls -lah1` |
| `rmd` | `rm -rfI` |

### Navigation
| Alias | Command |
|-------|---------|
| `..` | `cd ..` |
| `...` | `cd -` |
| `cd.` | `cd ~/.dotfiles` |
| `cdv` | `cd ~/.vim` |
| `cdd` | `cd ~/Desktop/` |
| `cdc` | `cd ~/Cave/` (Mountain Duck mount) |
| `cdp` | `cd ~/Projects/` |
| `cds` | `cd ~/Scratches/` |

### Clipboard
| Alias | Command |
|-------|---------|
| `pbc` / `pbp` | `pbcopy` / `pbpaste` |
| `cwd` | `pwd \| pbcopy` |
| `lcp` | `xclip -sel clip` |

### Edit configs
| Alias | Opens |
|-------|-------|
| `vb` / `vba` / `vbf` / `vbt` / `vbg` / `vbl` | bash profile / aliases / functions / tools / git / local |
| `vk` | kitty config |
| `vnv`, `nvc` | neovim config |
| `vt` | tmux config |
| `vg` | `~/.gitconfig` |
| `vetc` | `sudo nvim /etc/hosts` |

### Dev tools
| Alias | Command |
|-------|---------|
| `tm` / `tml` / `tma` / `tmk` | `tmux` / `ls` / `attach -t` / `kill-session -t` |
| `dcp` | `docker compose` |
| `npms` | `npm -s` |
| `flush` | flush DNS cache |

## Functions

**Directory navigation**
- `up [n]` (alias `ff`) — go up N levels (`up 3`).

**Bookmarks**
| Function | Usage |
|----------|-------|
| `mark <name>` | Bookmark current dir |
| `jump <name>` / `j <name>` | Jump to bookmark |
| `marks` | List bookmarks |
| `unmark <name>` | Remove bookmark |

```bash
cd ~/Projects/my-app && mark myapp
cd /elsewhere && j myapp          # back to ~/Projects/my-app
```

**System**
- `toggle_hidden` — show/hide dotfiles in Finder.
- `cave` — open the `~/Cave` Mountain Duck mount in Finder.

## Git Workflow

### Aliases
| Alias | Command |
|-------|---------|
| `gs` / `gf` | `git status` / `fetch` |
| `ga` / `gall` / `gau` / `gap` | `git add` / `--all` / `-u` / `-p` |
| `gcomm` | `git commit -m` |
| `gp` / `gpr` | `git pull` / `--rebase` |
| `gb` / `gco` / `gcb` | `git branch` / `checkout` / `checkout -b` |
| `gbcp` | Copy current branch name to clipboard |
| `gr` / `grh` | `git reset` / `--hard` |
| `gam` / `gamn` | `git commit --amend` / `--no-edit` |
| `gd` / `gds` | `git diff` / `--staged` |
| `gfd` | List files in last commit |
| `glog` | Pretty log (`git plog`) |

### Functions
- `gbu` — set upstream to `origin/<current-branch>`.
- `gcg <pattern>` — checkout first branch matching pattern.
- `gcrb <name>` — create branch `remote-run/<name>`.
- `gpush [--force]` — push current branch to origin.
- `gup <message>` — commit and push in one step.
- `roob [branch]` — rebase current branch on `branch` (default branch if omitted).

## Tool Integration

Auto-loaded in all shells with tab completion: **nvm** (`~/.nvm`), **pyenv** (`~/.pyenv`), **direnv** (`.envrc`), **ngrok** (if installed).

## Customization

Machine-specific aliases, exports, and PATH go in `bash_profile_local` (`vbl`); run `sb` to reload.
