# Security Policy

MyPowerShell is a PowerShell environment configuration tool that downloads and installs third-party software from the internet. This document outlines the security measures implemented and considerations for users.

## Security Measures

### 1. Package Manager Security
All tools are installed via trusted package managers:
- **winget**: Microsoft's official Windows package manager
- **scoop**: Community-maintained package manager with verified manifests
- **PowerShell Gallery**: Official Microsoft module repository (PSFzf)

The installer:
- Uses only official package manager commands
- Does **not** download executables directly
- Verifies package existence before installation
- Falls back to scoop if winget fails

### 2. No Administrator Privileges Required
- **User-Level Installation**: All tools install to user directories (`~\scoop\`)
- **No UAC Prompts**: Installation runs without elevation
- **Profile Modification**: Only modifies user's PowerShell profile (`$PROFILE`)
- **Config Files**: Deployed to user's home directory (`~\.config\`)

### 3. Error Handling Strategy
- **Pragmatic Approach**: Warns on errors but continues installation
- **Graceful Degradation**: Missing tools are skipped, not fatal
- **Status Reporting**: Clear feedback on success/failure for each component
- **Non-Destructive**: Existing configurations are overwritten but not deleted

### 4. Code Quality
- **UTF-8 Encoding**: All scripts use UTF-8 with BOM for PowerShell compatibility
- **Error Action Preference**: Uses `-ErrorAction SilentlyContinue` for optional features
- **Input Validation**: User responses validated before use
- **Quoted Paths**: All file paths properly quoted to handle spaces

### 5. Configuration File Safety
- **Automatic Overwrites**: Configs overwrite existing files without prompting (by design)
- **Version Control**: Tracked in git for easy rollback
- **Cross-Platform Configs**: starship.toml and delta.gitconfig copied from MyBash
- **JSON Merging**: Windows Terminal settings are merged, not replaced

## Security Considerations for Users

### Trust Chain

This installer relies on the security of:
- **winget/scoop**: Package manager integrity and manifest verification
- **GitHub**: For hosting this repository
- **PowerShell Gallery**: For PSFzf module
- **HTTPS/TLS**: For secure transmission
- **DNS**: For domain name resolution

### Recommended Practices

1. **Review Before Running**: Always read `install.ps1` before executing
2. **Run on Trusted Networks**: Avoid running installer on untrusted/public networks
3. **Backup Profile**: Backup existing `$PROFILE` before installation
   ```powershell
   Copy-Item $PROFILE "$PROFILE.backup"
   ```
4. **Git Tracking**: Keep mypowershell directory in git for easy rollback

### What the Installer Modifies

- **PowerShell Profile**: Adds MyPowerShell hook to `$PROFILE`
- **Config Files**: Deploys to `~\.config\` (starship.toml)
- **Windows Terminal**: Merges Tokyo Night theme into settings.json
- **Git Config**: Optionally includes delta.gitconfig (user prompted)
- **Environment**: No system PATH modifications (scoop handles this)

## Known Limitations

1. **Package Manager Trust**: Security depends on winget/scoop manifest integrity
2. **Third-Party Tools**: Security depends on upstream projects (starship, zoxide, etc.)
3. **Auto-Overwrite**: Configs overwrite without confirmation (intentional design choice)
4. **Windows Terminal Detection**: Auto-detects WT settings path (may fail on non-standard installations)

## Privacy

MyPowerShell does **not**:
- Send telemetry or analytics
- Connect to external servers (except package managers during installation)
- Collect user data
- Modify system-level settings
- Require online activation

Individual tools (starship, zoxide, etc.) may have their own telemetry - consult their documentation.

## Reporting Security Issues

If you discover a security vulnerability in MyPowerShell:

1. **Do NOT** open a public GitHub issue
2. Email: nick.tessier@proton.me
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

## Additional Resources

- [PowerShell Security Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/security/security-best-practices)
- [Scoop Security](https://github.com/ScoopInstaller/Scoop/wiki/Security)
- [Winget Security](https://learn.microsoft.com/en-us/windows/package-manager/winget/)

## Disclaimer

This software is provided "as is" without warranty of any kind. Users install and use this software at their own risk. Always review code before executing scripts, especially those that modify your shell environment.
