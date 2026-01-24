# Security Policy

MyBash V2 is a Bash environment configuration tool that downloads and installs third-party software from the internet. This document outlines the security measures implemented and considerations for users.

### 1. URL Validation
All downloads from GitHub are validated to ensure:
- URLs use HTTPS protocol
- URLs originate from `github.com` domain
- Prevents arbitrary URL injection attacks

### 2. Download Integrity
- **Retry Logic**: All downloads use curl/wget retry mechanisms (5 attempts, 3-second delays)
- **GPG Key Handling**: GPG keys are downloaded to temporary locations before import
- **Error Handling**: Failed downloads abort the installation process after exhausting retries
- **Network Resilience**: Handles connection timeouts, DNS failures, and temporary HTTP errors

### 3. Script Execution Safety
- **No Direct Piping**: External scripts are downloaded first, then executed (not piped directly to shell)
- **Explicit Permissions**: Downloaded scripts are made executable only when needed
- **Cleanup**: Temporary files are removed after installation

### 4. Privilege Management
- **User Confirmation**: Sudo usage requires explicit user consent
- **Graceful Fallback**: Can install tools locally without sudo when unavailable
- **Minimal Privileges**: Only requests elevated privileges when necessary

### 5. Code Quality
- **Error Exit**: `set -e` ensures script exits on errors
- **Quoted Variables**: Prevents word splitting and glob expansion vulnerabilities
- **Input Validation**: User responses are validated before use

## Security Considerations for Users

### Trust Chain

This installer relies on the security of:
- **GitHub**: For hosting official releases
- **Package Maintainers**: For official apt repositories
- **HTTPS/TLS**: For secure transmission
- **DNS**: For domain name resolution

### Recommended Practices

1. **Run on Trusted Networks**: Avoid running installer on untrusted/public networks
2. **Use Dedicated User**: Consider using a dedicated user account for testing
3. **Backup First**: Backup existing `.bashrc` and config files before installation

## Known Limitations

1. **GPG Key Distribution**: GPG keys are fetched from the same sources as the software
2. **Third-Party Trust**: Security depends on the security of upstream projects

## Audit History

- **2025-12-19**: Initial security audit and hardening
  - Added URL validation
  - Fixed curl pipe-to-shell pattern
  - Improved GPG key handling
  - Added comprehensive security documentation
- **2025-12-20**: Cleanup and Simplification
  - Removed checksum verification (high maintenance, low reliability)
  - Added server/headless installation mode
- **2025-12-19**: Kitty Terminal Migration (v2.0)
  - Replaced Snap-based Ghostty with official Kitty binary installer.
  - Verified Kitty installation script URLs and checksum patterns.
- **2025-12-19**: Modern CLI Tools Expansion (v2.1)
  - Added 12 new tools with GitHub binary installations and URL validation.
  - Implemented `setcap` configuration for `bandwhich` (requires user confirmation).
  - Added git configuration include for `delta`.
  - Conditional GPU detection for `nvtop` (APT-only).
- **2025-12-22**: Reliability and Uninstall Enhancements (v2.2)
  - Implemented download retry logic across all curl/wget operations
  - Added install manifest tracking system for safe uninstallation
  - Created uninstall.sh with timestamped .bashrc backups
  - Added `mybash doctor` command for read-only health checks
  - Removed nerdfetch to improve startup performance
  - All new scripts follow principle of least privilege

## Additional Resources

- [OWASP Bash Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Shell_Script_Security_Cheat_Sheet.html)
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)
- [ShellCheck](https://www.shellcheck.net/) - Shell script static analysis tool

## Disclaimer

This software is provided "as is" without warranty of any kind. Users install and use this software at their own risk. Always review code before executing it with elevated privileges.
