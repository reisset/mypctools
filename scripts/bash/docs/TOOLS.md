# 📚 MyBash V2.3 - Modern CLI Tools Guide

Welcome to the **Learning-First** toolset. This guide helps you navigate the modern CLI landscape while keeping your traditional Linux skills sharp.

## 💡 Quick Access

- **mybash -h** - Show help and quick alias reference
- **mybash tools** - View this guide with pretty formatting (uses glow)
- **mybash doctor** - Check if your MyBash setup is healthy and troubleshoot issues

## 🧠 Philosophy: Learning-First
MyBash V2.3 adds powerful modern tools but **does not replace** the originals.
- `cd`, `du`, `find`, and `ps` work exactly as they do on any standard Linux system.
- Modern tools are provided as **separate commands** (e.g., `z`, `dust`, `fd`).
- This ensures your muscle memory remains compatible with "vanilla" systems like a Raspberry Pi or a fresh server.

---

## 🛠️ Tool Reference

### 1. Navigation & Search
| Modern Tool | Command | Standard Equivalent | Why use it? |
| :--- | :--- | :--- | :--- |
| **zoxide** | `z`, `zi` | `cd` | Jumps to frequent directories by name. |
| **fd** | `fd` | `find` | Much faster, simpler syntax, ignores `.git`. |
| **fzf** | `Ctrl+t`, `Ctrl+r` | `grep`, `history` | Fuzzy finder with live previews. |

### 2. System Monitoring
| Modern Tool | Command | Standard Equivalent | Why use it? |
| :--- | :--- | :--- | :--- |
| **btop** | `btop` | `top`, `htop` | Beautiful UI, mouse support, network/disk monitoring. |
| **procs** | `px` | `ps` | Colored output, human-readable columns, search. |
| **dust** | `dust` | `du -sh` | Visual tree of disk usage. |
| **nvtop** | `nvtop` | N/A | Monitor GPU usage (NVIDIA/AMD/Intel). |

### 3. Development & Utilities
| Modern Tool | Command | Description |
| :--- | :--- | :--- |
| **tealdeer** | `tldr` | Practical examples for any command (instead of long man pages). |
| **lazygit** | `lg` | Incredible TUI for managing git repos, commits, and branches. |
| **gh** | `gh` | GitHub CLI for PRs, issues, actions, and repo management. |
| **delta** | `git diff` | Syntax highlighting and side-by-side diffs for Git. |
| **glow** | `glow` | Render markdown in the terminal. |
| **micro** | `m`, `edit` | Modern, intuitive terminal text editor. |

### 4. Kitty Kittens (Terminal Eye Candy)
| Kitten | Command / Shortcut | Description |
| :--- | :--- | :--- |
| **icat** | `icat <image>` | Display images directly in the terminal. |
| **kdiff** | `kdiff <file1> <file2>` | Syntax-highlighted side-by-side diff viewer. |
| **hints** | `Ctrl+Shift+E` | Make URLs, paths, git hashes clickable with keyboard. |
| **hints (paths)** | `Ctrl+Shift+P` then `F` | Quick file path selection mode. |
| **unicode_input** | `Ctrl+Shift+U` | Browse and insert emojis/unicode symbols. |
| **themes** | `Ctrl+Shift+F5` | Live preview and switch Kitty color themes. |

---

## ⌨️ Quick Shortcuts
- `tools`: Show this guide.
- `lg`: Open LazyGit.
- `zi`: Interactive directory jumper (zoxide).
- `px`: List processes (procs).
- `tldr <cmd>`: Get quick help for a command.

---

## 🚀 Power Mode (Optional)
If you decide you want to fully commit to the modern tools and replace standard commands, see `scripts/aliases.sh`. There is a commented-out section for "Power Mode". 

**Warning:** This will break muscle memory for vanilla systems. Use with caution!
