# 📚 MyPowerShell - Modern CLI Tools Guide

Welcome to the **Learning-First** toolset for Windows. This guide helps you navigate modern CLI tools while keeping your PowerShell fundamentals strong.

## 💡 Quick Access

- **tools** - View this guide (uses bat or glow if available)
- **Get-Command** - PowerShell's built-in command discovery
- **Get-Help <command>** - PowerShell's help system

## 🧠 Philosophy: Learning-First
MyPowerShell adds powerful modern tools but **does not replace** PowerShell fundamentals.
- `cd`, `Get-ChildItem`, `Get-Process`, and `Get-Content` work exactly as they do in standard PowerShell.
- Modern tools are provided as **separate commands or aliases** (e.g., `z`, `dust`, `fd`).
- This ensures your skills remain compatible with vanilla Windows systems and corporate environments.

---

## 🛠️ Tool Reference

### 1. Navigation & File Management
| Modern Tool | Command | PowerShell Equivalent | Why use it? |
| :--- | :--- | :--- | :--- |
| **zoxide** | `z`, `zi` | `cd`, `Set-Location` | Jumps to frequent directories by name. |
| **fd** | `fd`, `find` | `Get-ChildItem -Recurse` | Much faster, simpler syntax, ignores `.git`. |
| **fzf** | `Ctrl+t`, `Ctrl+r` | Manual search | Fuzzy finder with live previews. |
| **eza** | `ls`, `ll`, `la`, `lt` | `Get-ChildItem`, `dir` | Beautiful file listings with icons and colors. |
| **bat** | `cat` | `Get-Content`, `gc` | Syntax highlighting for file viewing. |
| **glow** | `glow <file.md>` | `Get-Content` | Beautiful markdown rendering in terminal. |
| **ripgrep** | `rg`, `grep` | `Select-String`, `sls` | Ultra-fast text search across files. |

### 2. System Monitoring & Analysis
| Modern Tool | Command | PowerShell Equivalent | Why use it? |
| :--- | :--- | :--- | :--- |
| **dust** | `dust` | `Get-PSDrive` | Visual tree of disk usage with colors. |
| **gsudo** | `sudo <command>` | `Start-Process -Verb RunAs` | Elevate commands without opening new window. |

### 3. Development Tools
| Modern Tool | Command | Description |
| :--- | :--- | :--- |
| **lazygit** | `lg` | Incredible TUI for managing git repos, commits, and branches. |
| **delta** | `git diff` | Syntax highlighting and side-by-side diffs for Git. |
| **jq** | `jq`, `jqc` | JSON processor - parse, filter, transform JSON data. `jqc` reads from clipboard. |
| **starship** | Auto-loads | Cross-shell prompt with git status and language versions. |

---

## ⌨️ Quick Shortcuts & Aliases

### Navigation
- `z <dir>` - Jump to frequently used directories
- `zi` - Interactive directory picker (zoxide + fzf)
- `..` - Go up one directory (`cd ..`)
- `...` - Go up two directories (`cd ..\..`)
- `....` - Go up three directories

### File Operations
- `ls` - List files with icons (eza)
- `ll` - Detailed list with permissions and sizes (eza -al)
- `la` - List all files including hidden (eza -a)
- `lt` - Tree view of directory structure (eza --tree)
- `cat <file>` - View file with syntax highlighting (bat)

### Git Shortcuts
- `g` - Alias for `git`
- `gs` - `git status`
- `ga` - `git add`
- `gc` - `git commit`
- `gp` - `git push`
- `gl` - `git pull`
- `gd` - `git diff` (uses delta for beautiful output)
- `lg` - Open LazyGit TUI

### Search & Find
- `fd <pattern>` - Fast file search
- `rg <pattern>` - Fast text search in files
- `Ctrl+R` - Fuzzy search command history
- `Ctrl+T` - Fuzzy find files in current directory

### Development & Utilities
- `jq '.key' file.json` - Parse and filter JSON files
- `jqc '.key'` - Parse JSON from clipboard
- `glow README.md` - View markdown files with beautiful formatting
- `sudo notepad C:\Windows\System32\hosts` - Elevate commands without new window

---

## 🔧 PowerShell-Specific Tips

### PowerShell Native Commands Still Work
- `Get-ChildItem` / `gci` / `dir` - Standard file listing
- `Get-Content` / `gc` / `type` - Read file contents
- `Select-String` / `sls` - Search text in files
- `Get-Process` / `gps` / `ps` - List processes
- `Get-Service` - List Windows services
- `Get-Help` - PowerShell documentation

### Discovering Commands
```powershell
Get-Command *process*     # Find commands about processes
Get-Alias ls              # See what 'ls' points to
Get-Help Get-ChildItem    # Read full help for a command
```

---

## 🚀 Power Mode (Optional)
If you want to fully commit to modern tools and replace standard navigation, see `scripts/aliases.ps1`. There is a commented-out "POWER MODE" section that makes `cd` → `z`.

**Warning:** This will break muscle memory for vanilla Windows systems. Use with caution!

---

## 📖 Additional Resources

- **FZF Preview**: Uses bat for syntax highlighting in Ctrl+T preview
- **PSReadLine**: Enhanced history search with predictions
- **Starship Config**: `~\.config\starship.toml`
- **Profile Location**: `$PROFILE` (run to see path)

---

## 🎨 Visual Enhancements

- **Nerd Font**: JetBrainsMono Nerd Font (install via scoop)
- **Color Scheme**: Tokyo Night (Windows Terminal)
- **Icons**: Supported in eza, starship prompt

---

**Need Help?** Run `tools` anytime to see this guide!
