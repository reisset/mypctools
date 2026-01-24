# MyPowerShell Uninstaller
# Removes MyPowerShell configuration and restores default PowerShell environment
# Inspired by MyBash uninstall patterns
# Version: 1.1.2 (Fixed: Scoop false-positive detection + output polish)

#Requires -Version 5.1

# ============================================================================
# Helper Functions
# ============================================================================

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Log-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Confirm {
    param([string]$Message)
    Write-Host "[?] $Message (y/N) " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    return $response -match '^[Yy]$'
}

function Write-Banner {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "║                   MyPowerShell Uninstaller                    ║" -ForegroundColor Cyan
    Write-Host "║          Restores Native PowerShell Environment               ║" -ForegroundColor Cyan
    Write-Host "║                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# Main Uninstall Script
# ============================================================================

Write-Banner

# Track what was done for summary
$script:ActionsPerformed = @()

# ============================================================================
# Step 1: Clean up PowerShell Profile
# ============================================================================

Log-Info "Step 1: Cleaning up PowerShell profile"

if (-not (Test-Path $PROFILE)) {
    Log-Warn "Profile not found at: $PROFILE"
    Log-Warn "Skipping profile cleanup."
} else {
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

    if ($profileContent -match '# MyPowerShell Configuration') {
        if (Confirm "Remove MyPowerShell from profile?") {
            # Create backup
            $backupPath = "$PROFILE.mypowershell-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $PROFILE $backupPath -ErrorAction SilentlyContinue
            Log-Info "Created backup: $backupPath"

            # Remove the MyPowerShell block
            # Pattern: Remove from "# ===...MyPowerShell" through the ". " line
            # Updated regex to handle optional comment lines between header and source line
            $pattern = '(?ms)^# ={70,}\s*\r?\n# MyPowerShell Configuration\s*\r?\n# ={70,}\s*\r?\n(?:#[^\r\n]*\r?\n)*\. [^\r\n]*profile\.ps1[^\r\n]*\r?\n?'
            $newContent = $profileContent -replace $pattern, ''

            # Write back to profile
            Set-Content -Path $PROFILE -Value $newContent -NoNewline
            Log-Info "Removed MyPowerShell from profile"
            $script:ActionsPerformed += "Removed MyPowerShell hook from profile"
        } else {
            Log-Info "Skipped profile cleanup"
        }
    } else {
        Log-Warn "MyPowerShell configuration not found in profile"
    }
}

Write-Host ""

# ============================================================================
# Step 2: Remove Starship Configuration
# ============================================================================

Log-Info "Step 2: Removing Starship configuration"

$starshipConfig = "$env:USERPROFILE\.config\starship.toml"
if (Test-Path $starshipConfig) {
    if (Confirm "Remove starship.toml configuration?") {
        Remove-Item $starshipConfig -Force -ErrorAction SilentlyContinue
        Log-Info "Removed $starshipConfig"
        $script:ActionsPerformed += "Removed Starship config"
    } else {
        Log-Info "Skipped Starship config removal"
    }
} else {
    Log-Warn "Starship config not found at: $starshipConfig"
}

Write-Host ""

# ============================================================================
# Step 3: Remove Cached Init Scripts
# ============================================================================

Log-Info "Step 3: Removing cached init scripts"

$cacheFiles = @(
    "$env:TEMP\mypowershell-starship-init.ps1",
    "$env:TEMP\mypowershell-zoxide-init.ps1"
)

$removedCount = 0
foreach ($file in $cacheFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        $removedCount++
    }
}

if ($removedCount -gt 0) {
    Log-Info "Removed $removedCount cached init script(s)"
    $script:ActionsPerformed += "Removed cached init scripts"
} else {
    Log-Warn "No cached init scripts found"
}

Write-Host ""

# ============================================================================
# Step 4: Remove Git Delta Configuration
# ============================================================================

Log-Info "Step 4: Checking Git delta configuration"

# Check if git is available
if (Get-Command git -ErrorAction SilentlyContinue) {
    # Get all include.path entries
    $gitIncludes = git config --global --get-all include.path 2>$null

    # Find MyPowerShell delta config
    $deltaConfig = $gitIncludes | Where-Object { $_ -like '*mypowershell*delta.gitconfig*' }

    if ($deltaConfig) {
        Log-Info "Found git delta configuration: $deltaConfig"
        if (Confirm "Remove git delta configuration?") {
            # Remove the specific include path
            git config --global --unset include.path "$deltaConfig" 2>$null
            Log-Info "Removed git delta configuration"
            $script:ActionsPerformed += "Removed git delta config"
        } else {
            Log-Info "Skipped git delta config removal"
        }
    } else {
        Log-Warn "No MyPowerShell git delta configuration found"
    }
} else {
    Log-Warn "Git not found, skipping delta configuration check"
}

Write-Host ""

# ============================================================================
# Step 5: Remove Windows Terminal Additions
# ============================================================================

Log-Info "Step 5: Checking Windows Terminal configuration"

# Find Windows Terminal settings
$wtSettingsPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

if ($wtSettingsPath -and (Test-Path $wtSettingsPath)) {
    Log-Info "Found Windows Terminal settings: $wtSettingsPath"

    if (Confirm "Remove Tokyo Night theme from Windows Terminal?") {
        try {
            $wtSettings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
            $modified = $false

            # Remove Tokyo Night scheme from schemes array
            if ($wtSettings.schemes) {
                $originalCount = $wtSettings.schemes.Count
                $wtSettings.schemes = @($wtSettings.schemes | Where-Object { $_.name -ne "Tokyo Night" })
                if ($wtSettings.schemes.Count -lt $originalCount) {
                    Log-Info "Removed Tokyo Night color scheme"
                    $modified = $true
                }
            }

            # Remove our settings from default profile
            if ($wtSettings.profiles.defaults) {
                $defaults = $wtSettings.profiles.defaults
                $removed = @()

                if ($defaults.colorScheme -eq "Tokyo Night") {
                    $defaults.PSObject.Properties.Remove('colorScheme')
                    $removed += "colorScheme"
                }

                if ($defaults.font -and $defaults.font.face -eq "JetBrainsMono Nerd Font") {
                    if ($defaults.font.PSObject.Properties.Name.Count -eq 1) {
                        $defaults.PSObject.Properties.Remove('font')
                    } else {
                        $defaults.font.PSObject.Properties.Remove('face')
                    }
                    $removed += "font.face"
                }

                if ($defaults.font -and $defaults.font.size -eq 15) {
                    if ($defaults.font.PSObject.Properties.Name.Count -eq 1) {
                        $defaults.PSObject.Properties.Remove('font')
                    } else {
                        $defaults.font.PSObject.Properties.Remove('size')
                    }
                    $removed += "font.size"
                }

                if ($defaults.padding -eq "10") {
                    $defaults.PSObject.Properties.Remove('padding')
                    $removed += "padding"
                }

                if ($removed.Count -gt 0) {
                    Log-Info "Removed profile settings: $($removed -join ', ')"
                    $modified = $true
                }
            }

            if ($modified) {
                # Save back to file
                $wtSettings | ConvertTo-Json -Depth 10 | Set-Content $wtSettingsPath -Encoding UTF8
                Log-Info "Updated Windows Terminal settings"
                $script:ActionsPerformed += "Removed Windows Terminal customizations"
            } else {
                Log-Warn "No MyPowerShell customizations found in Windows Terminal"
            }
        } catch {
            Log-Error "Failed to modify Windows Terminal settings: $_"
        }
    } else {
        Log-Info "Skipped Windows Terminal cleanup"
    }
} else {
    Log-Warn "Windows Terminal settings not found"
}

Write-Host ""

# ============================================================================
# Step 6: Uninstall Tools (Automatic, Prompted)
# ============================================================================

Log-Info "Step 6: Tool uninstallation"
Write-Host ""

$toolsUninstalled = @()
$anyToolsSkipped = $false

# Core Tools
if (Confirm "Uninstall Core tools (starship, zoxide, fzf, eza, bat, fd, rg)?") {
    Log-Info "Uninstalling Core tools..."

    # Define core tools with their package IDs
    $coreTools = @(
        @{Name='starship'; Winget='Starship.Starship'; Scoop='starship'},
        @{Name='zoxide'; Winget='ajeetdsouza.zoxide'; Scoop='zoxide'},
        @{Name='fzf'; Winget='junegunn.fzf'; Scoop='fzf'},
        @{Name='eza'; Winget='eza-community.eza'; Scoop='eza'},
        @{Name='ripgrep'; Winget='BurntSushi.ripgrep.MSVC'; Scoop='ripgrep'},
        @{Name='bat'; Winget=$null; Scoop='bat'},
        @{Name='fd'; Winget=$null; Scoop='fd'}
    )

    foreach ($tool in $coreTools) {
        $uninstalled = $false

        # Try winget first if available
        if ($tool.Winget) {
            Write-Host "  Uninstalling $($tool.Name) via winget..." -ForegroundColor Gray
            $result = winget uninstall $tool.Winget --silent 2>&1
            if ($LASTEXITCODE -eq 0) {
                $uninstalled = $true
            }
        }

        # Fallback to scoop
        if (-not $uninstalled -and $tool.Scoop) {
            Write-Host "  Uninstalling $($tool.Name) via scoop..." -ForegroundColor Gray
            $result = scoop uninstall $tool.Scoop 2>&1
            $resultText = ($result | Out-String)
            if ($LASTEXITCODE -eq 0 -and $resultText -notmatch "isn't installed") {
                $uninstalled = $true
            }
        }

        if ($uninstalled) {
            Write-Host "    ✓ $($tool.Name) uninstalled" -ForegroundColor Green
            $toolsUninstalled += $tool.Name
        } else {
            Write-Host "    - $($tool.Name) not found or already uninstalled" -ForegroundColor Gray
        }
    }
} else {
    Log-Info "Skipped Core tools uninstallation"
    $anyToolsSkipped = $true
}

Write-Host ""

# Dev Tools
if (Confirm "Uninstall Dev tools (lazygit, delta, dust)?") {
    Log-Info "Uninstalling Dev tools..."

    $devTools = @(
        @{Name='lazygit'; Winget='JesseDuffield.Lazygit'; Scoop='lazygit'},
        @{Name='delta'; Winget=$null; Scoop='delta'},
        @{Name='dust'; Winget=$null; Scoop='dust'}
    )

    foreach ($tool in $devTools) {
        $uninstalled = $false

        if ($tool.Winget) {
            Write-Host "  Uninstalling $($tool.Name) via winget..." -ForegroundColor Gray
            $result = winget uninstall $tool.Winget --silent 2>&1
            if ($LASTEXITCODE -eq 0) {
                $uninstalled = $true
            }
        }

        if (-not $uninstalled -and $tool.Scoop) {
            Write-Host "  Uninstalling $($tool.Name) via scoop..." -ForegroundColor Gray
            $result = scoop uninstall $tool.Scoop 2>&1
            $resultText = ($result | Out-String)
            if ($LASTEXITCODE -eq 0 -and $resultText -notmatch "isn't installed") {
                $uninstalled = $true
            }
        }

        if ($uninstalled) {
            Write-Host "    ✓ $($tool.Name) uninstalled" -ForegroundColor Green
            $toolsUninstalled += $tool.Name
        } else {
            Write-Host "    - $($tool.Name) not found or already uninstalled" -ForegroundColor Gray
        }
    }
} else {
    Log-Info "Skipped Dev tools uninstallation"
    $anyToolsSkipped = $true
}

Write-Host ""

# Optional Tools
if (Confirm "Uninstall Optional tools (yazi, tealdeer, glow, jq, gsudo)?") {
    Log-Info "Uninstalling Optional tools..."

    $optionalTools = @(
        @{Name='yazi'; Scoop='yazi'},
        @{Name='tealdeer'; Scoop='tealdeer'},
        @{Name='glow'; Scoop='glow'},
        @{Name='jq'; Scoop='jq'},
        @{Name='gsudo'; Scoop='gsudo'}
    )

    foreach ($tool in $optionalTools) {
        Write-Host "  Uninstalling $($tool.Name) via scoop..." -ForegroundColor Gray
        $result = scoop uninstall $tool.Scoop 2>&1
        $resultText = ($result | Out-String)
        if ($LASTEXITCODE -eq 0 -and $resultText -notmatch "isn't installed") {
            Write-Host "    ✓ $($tool.Name) uninstalled" -ForegroundColor Green
            $toolsUninstalled += $tool.Name
        } else {
            Write-Host "    - $($tool.Name) not found or already uninstalled" -ForegroundColor Gray
        }
    }
} else {
    Log-Info "Skipped Optional tools uninstallation"
    $anyToolsSkipped = $true
}

Write-Host ""

# PSFzf Module
if (Confirm "Uninstall PSFzf PowerShell module?") {
    Log-Info "Uninstalling PSFzf module..."
    try {
        Uninstall-Module -Name PSFzf -AllVersions -Force -ErrorAction Stop
        Write-Host "  ✓ PSFzf module uninstalled" -ForegroundColor Green
        $toolsUninstalled += "PSFzf"
        $script:ActionsPerformed += "Uninstalled PSFzf module"
    } catch {
        Log-Warn "PSFzf module not found or already uninstalled"
    }
} else {
    Log-Info "Skipped PSFzf module uninstallation"
    $anyToolsSkipped = $true
}

if ($toolsUninstalled.Count -gt 0) {
    $script:ActionsPerformed += "Uninstalled tools: $($toolsUninstalled -join ', ')"
}

Write-Host ""

# Show manual commands if any tools were skipped
if ($anyToolsSkipped) {
    Log-Info "Manual uninstallation commands (if needed later):"
    Write-Host ""
    Write-Host "  winget uninstall Starship.Starship ajeetdsouza.zoxide junegunn.fzf eza-community.eza ..." -ForegroundColor Gray
    Write-Host "  scoop uninstall bat fd delta dust yazi tealdeer" -ForegroundColor Gray
    Write-Host "  Uninstall-Module PSFzf -AllVersions" -ForegroundColor Gray
    Write-Host ""
}

Log-Info "To delete MyPowerShell folder: Remove-Item -Recurse -Force '$PSScriptRoot'"
Log-Info "Note: JetBrainsMono Nerd Font was intentionally left installed"

Write-Host ""

# ============================================================================
# Step 7: Reset Current Session
# ============================================================================

Log-Info "Step 7: Resetting current session"

# Reset prompt to default PowerShell
function global:prompt {
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}

# Disable PSReadLine predictions (the ListView feature)
try {
    Set-PSReadLineOption -PredictionSource None -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
    Log-Info "Disabled PSReadLine predictions"
} catch {
    # PSReadLine not available or already disabled
}

# Clear MyPowerShell environment variables
if (Test-Path Env:STARSHIP_CONFIG) {
    Remove-Item Env:STARSHIP_CONFIG -ErrorAction SilentlyContinue
}
if (Test-Path Env:MYPOWERSHELL_WELCOME_SHOWN) {
    Remove-Item Env:MYPOWERSHELL_WELCOME_SHOWN -ErrorAction SilentlyContinue
}

Log-Info "Session reset to default PowerShell"
$script:ActionsPerformed += "Reset current session (prompt + predictions)"

Write-Host ""

# ============================================================================
# Step 8: Summary and Next Steps
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                               ║" -ForegroundColor Green
Write-Host "║                  Uninstallation Complete! ✓                   ║" -ForegroundColor Green
Write-Host "║                                                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($script:ActionsPerformed.Count -gt 0) {
    Write-Host "Actions performed:" -ForegroundColor Cyan
    foreach ($action in $script:ActionsPerformed) {
        Write-Host "  • $action" -ForegroundColor Gray
    }
} else {
    Write-Host "No actions were performed (all steps skipped)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Your session has been reset:" -ForegroundColor Cyan
Write-Host "  ✓ Prompt reset to 'PS C:\>'" -ForegroundColor Green
Write-Host "  ✓ PSReadLine predictions disabled" -ForegroundColor Green
Write-Host "  ✓ Environment variables cleared" -ForegroundColor Green
Write-Host ""
Write-Host "New PowerShell sessions will also load cleanly." -ForegroundColor Gray
Write-Host ""
Write-Host "To reinstall later: " -ForegroundColor Gray -NoNewline
Write-Host ".\install.ps1" -ForegroundColor Yellow
Write-Host ""
