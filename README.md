# 🏡 Dotfiles

> Automated macOS development environment — shell, terminal, editor, and a Claude Code workflow.

## 📋 Contents

- [🚀 Quick Start](#-quick-start)
- [⚡ What's Included](#-whats-included)
- [🔧 Installation](#-installation)
- [📁 Configuration Structure](#-configuration-structure)
- [🤖 Claude Code Workflow](#-claude-code-workflow)
- [🎨 Customization](#-customization)
- [🔄 Management](#-management)
- [🔍 Troubleshooting](#-troubleshooting)
- [📚 Resources](#-resources)

---

## 🚀 Quick Start

**Prerequisites:** macOS, Xcode Command Line Tools, internet connection.

```bash
# 1. Core — Homebrew, packages, config symlinks, Claude CLI (use bash for color)
cd ~ && git clone https://github.com/yoaquim/.dotfiles.git && cd .dotfiles && bash ./install.sh

# 2. Languages — Node LTS (nvm) + latest Python (pyenv)
bash ./post-setup.sh

# 3. AstroNvim — needs SSH keys (~/.ssh/git[.pub]) added to GitHub
bash ./setup-astronvim.sh

# 4. Claude Code config — after the Claude CLI is installed
cd ~/.dotfiles/claude && ./setup.sh
```

---

## ⚡ What's Included

| Area | Tools |
|------|-------|
| **Shell** | Modern Bash — vim editing, 50+ aliases, directory bookmarking, eternal history, Base16 themes |
| **Terminal** | Kitty (GPU-accelerated, ligatures), Tmux + Powerline, JetBrains Mono Nerd Font |
| **Editor** | AstroNvim (Neovim distribution) |
| **Dev** | Git + git-delta, Node via nvm, Python via pyenv, Go, Claude Code |
| **Package managers** | Homebrew, nvm, pyenv, pipx, TPM (tmux plugins) |
| **CLI utils** | ripgrep, fd, lazygit, bottom, tldr, gdu, tree-sitter |
| **Apps** | Alfred, Rectangle, Hammerspoon, 1Password, Slack, Notion, Spotify, Postman, Calibre, Quarto (full list in `install.sh` casks) |

> Docker is disabled by default (package conflicts) — install manually with `brew install --cask docker` if needed.

---

## 🔧 Installation

`install.sh` modes:

| Command | Description |
|---------|-------------|
| `./install.sh` | Full installation (default) |
| `./install.sh --reinstall` | Reinstall configurations only |
| `./install.sh --force` | Force reinstall without prompts |
| `./install.sh --uninstall` | Remove all configurations |
| `./install.sh --help` | Show all options |

Four scripts, run in order (see [Quick Start](#-quick-start)):

| Script | Does |
|--------|------|
| `install.sh` | Homebrew, packages/casks/fonts, config symlinks (backs up existing), TPM + Base16, Claude CLI |
| `post-setup.sh` | Node LTS via nvm, latest Python via pyenv |
| `setup-astronvim.sh` | Clones AstroNvim, links `polish.lua` / `user.lua` (requires SSH keys) |
| `claude/setup.sh` | Symlinks Claude skills/agents/hooks/scripts/practices/settings into `~/.claude/` |

---

## 📁 Configuration Structure

```
~/.dotfiles/
├── install.sh / post-setup.sh / setup-astronvim.sh   # setup scripts
├── change-shell.sh                                    # shell change helper
├── config/                       # dotfile configs (symlinked into place)
│   ├── bash/                     # bash_profile + aliases, functions, git, tools, ssh, local
│   ├── kitty/                    # terminal config
│   ├── tmux/  + tmux-powerline/  # multiplexer + status bar
│   ├── nvim/                     # AstroNvim polish.lua + user.lua
│   ├── hammerspoon/              # hotkeys & automation
│   ├── mountainduck/             # S3 (Cave) bookmark
│   ├── cmux/  ghostty/           # cmux + Ghostty terminal configs
│   └── ssh/  git/  gitconfig     # ssh + git config (git/config.local not in git)
└── claude/                       # Claude Code config — see Claude Code Workflow below
    ├── setup.sh  settings.json
    └── agents/  scripts/  hooks/  practices/  skills/  statusline/
```

Each `config/<tool>/` has its own README — see [Resources](#-resources).

### Symlinks

| Source | Target |
|--------|--------|
| `config/bash/bash_profile` | `~/.bash_profile`, `~/.bashrc` |
| `config/bash/` | `~/.config/bash/` |
| `config/tmux/` | `~/.config/tmux/` |
| `config/kitty/` | `~/.config/kitty/` |
| `config/gitconfig` | `~/.gitconfig` |
| `config/nvim/polish.lua` | `~/.config/nvim/lua/polish.lua` |
| `config/nvim/user.lua` | `~/.config/nvim/lua/plugins/user.lua` |
| `config/hammerspoon/` | `~/.hammerspoon/` |
| `config/ssh/config` | `~/.ssh/config` |
| `config/cmux/` | `~/.config/cmux/` |
| `config/ghostty/` | `~/.config/ghostty/` |
| `claude/{skills,agents,hooks,scripts,practices,statusline}/` | `~/.claude/…` (via `claude/setup.sh`) |
| `claude/settings.json` | `~/.claude/settings.json` |

`claude/setup.sh` also installs the `com.yoaquim.dispatch-watchdog` LaunchAgent (resumes halted dispatch runners every ~10 min).

---

## 🤖 Claude Code Workflow

Custom Claude Code configuration: skills, agents, hooks, and practices. Install with `cd ~/.dotfiles/claude && ./setup.sh`. Edit in `~/.dotfiles/claude/` — changes apply globally via symlinks.

### Skills

| Skill | Purpose |
|-------|---------|
| `/setup` | Init project: CLAUDE.md, git, hooks, deps |
| `/sketch <name>` | Lightweight local spec (ZeeSpec-lite) |
| `/spec` | Linear feature spec with sub-issues (ZeeSpec) |
| `/issue` | Single well-formed Linear issue |
| `/dispatch <id\|name> [--repo <r>]` | Spawn runner from Linear ticket or sketch (`--repo` targets another repo) |
| `/pr` | Review, fix, create PR |
| `/pr-review` | Bug-focused PR review with watch loop |
| `/debug` | Systematic root-cause debugging |
| `/gh-stack` | Stacked branches and PRs |
| `/handoff` | Distill the session into a handoff doc (alternative to lossy compaction) |
| `/pickup` | Resume a fresh session from the latest handoff + Linear + code |

### Workflows

```
Local:   /sketch jwt-auth → /dispatch jwt-auth → runner → /pr
Linear:  /spec → /dispatch ENG-142 → runner → /pr
```

### Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `inject-practices.sh` | Runner SessionStart | Auto-detect and inject practices |
| `lint-spec.sh` | Write/Edit on sketches | Scope check (>8 steps, >10 files) |
| `validate-issue.sh` | Linear `save_issue` | Issue title/description style |
| `validate-commit.sh` | Bash (`git commit`) | Commit message style |
| `validate-pr.sh` | Bash (`gh pr create`) | Block non-conforming PR creation |
| `check-comment-slop.sh` | Runner Edit/Write | Block AI-slop code comments |
| `enforce-worktree.sh` | Runner Edit/Write | Block writes outside the runner's worktree |
| `enforce-completion.sh` | Runner Stop | Gate exit on PR + terminal status |
| `lint-shell.sh` | Edit/Write on shell files | shellcheck findings fed back to the agent |
| `notify-done.sh` | Stop | macOS notification when an interactive session ends |
| `enforce-created-summary.sh` | Stop | Require the standardized closing block after Linear creates |
| `auto-spawn-reviewer.sh` | Runner PostToolUse | Auto-spawn the PR watcher after `gh pr create` |
| `enforce-watch.sh` | Stop (pr-reviewer only) | Keep the PR watch loop alive until approved + CI green |

### Agent & Practices

One unified **runner** agent handles all dispatched work. On completion it pushes, creates a PR via `/pr`, spawns a `/pr-review` session, then loops — addressing review threads and pushing fixes until the PR is approved with green CI (or a cap is hit).

Practices auto-inject at runner startup. TDD, no-comments, verification, and receiving-review are always active; stack practices (Django, Rails, React, Tailwind, Docker, npm pinning, Terraform, Cloudflare Workers, Shell) activate on project files — see `claude/practices/INDEX.md`.

---

## 🎨 Customization

- **Colors:** Base16 schemes in `~/.config/base16-shell/`; switch with `base16_<theme>` (applies to tmux, vim, shell).
- **Machine-local (not in git):** personal aliases/exports in `~/.config/bash/bash_profile_local`; machine git settings in `~/.config/git/config.local`.
- **Plugins:** tmux `` ` I `` (install) / `` ` U `` (update); Neovim `:Lazy`.

---

## 🔄 Management

```bash
# Update everything
cd ~/.dotfiles && git pull && ./install.sh --reinstall

# Update packages / language versions
brew update && brew upgrade
nvm install --lts
```

Reinstalling backs up replaced files as `filename.backup.YYYYMMDD_HHMMSS` (restore by copying back). Clean old backups: `find ~ -name "*.backup.*" -mtime +30 -delete`.

---

## 🔍 Troubleshooting

**Bash isn't the default shell**
```bash
sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
chsh -s /opt/homebrew/bin/bash
```

**Homebrew install fails** — ensure Command Line Tools: `xcode-select --install`, then re-run `./install.sh`.

**Tmux plugins not loading**
```bash
rm -rf ~/.config/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
# then inside tmux: ` I
```

**AstroNvim clone fails (SSH)** — `setup-astronvim.sh` needs SSH keys on GitHub:
```bash
ls -la ~/.ssh/git*            # keys present?
ssh -T git@github.com         # auth works?
# if missing:
ssh-keygen -t ed25519 -f ~/.ssh/git -C "you@example.com"
ssh-add ~/.ssh/git && cat ~/.ssh/git.pub   # add the pubkey at github.com/settings/keys
bash ./setup-astronvim.sh
```

**Missing fonts** — `brew install --cask font-jetbrains-mono-nerd-font`.

---

## 📚 Resources

Per-tool guides: [Bash](config/bash/README.md) · [Kitty](config/kitty/README.md) · [Tmux](config/tmux/README.md) · [Powerline](config/tmux-powerline/README.md) · [AstroNvim](config/nvim/README.md) · [Hammerspoon](config/hammerspoon/README.md) · [Mountain Duck](config/mountainduck/README.md)

External: [Homebrew](https://brew.sh/) · [Base16](https://github.com/chriskempson/base16) · [AstroNvim](https://astronvim.github.io/) · [Tmux Wiki](https://github.com/tmux/tmux/wiki)

> After install, open a new terminal (or `source ~/.bash_profile`) to activate everything.
