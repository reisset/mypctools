#Requires -Version 5.1
<#
.SYNOPSIS
    MyPowerShell Installer - High-performance PowerShell environment for Windows
.DESCRIPTION
    Installs modern CLI tools and configurations inspired by MyBash for Linux.
    Installs modern CLI tools (starship, zoxide, fzf, eza, bat, fd, ripgrep, lazygit, delta, dust) with Tokyo Night theme
.NOTES
    Version: 1.4.1
    No administrator privileges required
#>

param(
    [switch]$SkipConfirmation
)

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $color = switch ($Type) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }

    $prefix = switch ($Type) {
        'Info'    { '[*]' }
        'Success' { '[✓]' }
        'Warning' { '[!]' }
        'Error'   { '[✗]' }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-CommandExists {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Confirm {
    param(
        [string]$Message,
        [bool]$DefaultYes = $true
    )

    if ($SkipConfirmation) { return $true }

    $prompt = if ($DefaultYes) { "$Message [Y/n]" } else { "$Message [y/N]" }
    $response = Read-Host $prompt

    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }

    return $response -match '^[Yy]'
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$CommandName
    )

    if (Test-CommandExists $CommandName) {
        Write-Status "$CommandName is already installed" -Type Success
        return $true
    }

    Write-Status "Installing $CommandName via winget..." -Type Info
    try {
        $result = winget install --id $Id --source winget --accept-source-agreements --accept-package-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "$CommandName installed successfully" -Type Success
            return $true
        } else {
            Write-Status "winget install failed for $CommandName" -Type Warning
            return $false
        }
    } catch {
        Write-Status "Error installing $CommandName via winget: $_" -Type Warning
        return $false
    }
}

function Install-ScoopPackage {
    param([string]$Name)

    if (Test-CommandExists $Name) {
        Write-Status "$Name is already installed" -Type Success
        return $true
    }

    if (-not (Test-CommandExists 'scoop')) {
        Write-Status "Scoop not available, cannot install $Name" -Type Warning
        return $false
    }

    Write-Status "Installing $Name via scoop..." -Type Info
    try {
        scoop install $Name 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Status "$Name installed successfully" -Type Success
            return $true
        } else {
            Write-Status "Failed to install $Name via scoop" -Type Warning
            return $false
        }
    } catch {
        Write-Status "Error installing $Name via scoop: $_" -Type Error
        return $false
    }
}

# ============================================================================
# Header
# ============================================================================

Clear-Host
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║                    MyPowerShell Installer                     ║" -ForegroundColor Cyan
Write-Host "║     High-Performance PowerShell Environment for Windows       ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 1. Pre-flight Checks
# ============================================================================

Write-Status "Running pre-flight checks..." -Type Info

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
    Write-Status "PowerShell 5.1 or higher is required (you have $($psVersion))" -Type Error
    exit 1
}

if ($psVersion.Major -lt 7) {
    Write-Status "PowerShell $($psVersion) detected. PowerShell 7+ is recommended for better performance." -Type Warning
} else {
    Write-Status "PowerShell $($psVersion) detected" -Type Success
}

# Get script directory
$RepoDir = $PSScriptRoot
Write-Status "Repository directory: $RepoDir" -Type Info

# ============================================================================
# 2. Scoop Installation (Required for some tools)
# ============================================================================

Write-Host ""
Write-Status "Checking Scoop package manager..." -Type Info

if (-not (Test-CommandExists 'scoop')) {
    Write-Host ""
    if (Confirm "Scoop package manager is not installed. Install it now?") {
        try {
            Write-Status "Installing Scoop..." -Type Info

            # Set execution policy for current user
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue

            # Install Scoop
            Invoke-RestMethod get.scoop.sh | Invoke-Expression

            if (Test-CommandExists 'scoop') {
                Write-Status "Scoop installed successfully" -Type Success
            } else {
                Write-Status "Scoop installation may have failed. Some tools will be unavailable." -Type Warning
            }
        } catch {
            Write-Status "Failed to install Scoop: $_" -Type Error
            Write-Status "Continuing without Scoop. Some tools may not be available." -Type Warning
        }
    } else {
        Write-Status "Skipping Scoop installation. Some tools will be unavailable." -Type Warning
    }
} else {
    Write-Status "Scoop is already installed" -Type Success
}

# ============================================================================
# 3. Install Starship Prompt
# ============================================================================

Write-Host ""
Write-Status "Installing Starship prompt..." -Type Info

# Try winget first
$wingetSuccess = $false
if (Test-CommandExists 'winget') {
    $wingetSuccess = Install-WingetPackage -Id "Starship.Starship" -CommandName "starship"
}

# Fall back to scoop if winget failed
if (-not $wingetSuccess -and (Test-CommandExists 'scoop')) {
    Write-Status "Falling back to scoop for Starship installation..." -Type Info
    Install-ScoopPackage -Name "starship"
}

if (-not (Test-CommandExists 'starship')) {
    Write-Status "Failed to install Starship. Prompt customization will not be available." -Type Error
} else {
    Write-Status "Starship is ready" -Type Success
}

# ============================================================================
# 4. Install Tier 1 Tools (Core Navigation & File Tools)
# ============================================================================

Write-Host ""
Write-Status "Installing Tier 1 tools (navigation & file tools)..." -Type Info

# Track installation status
$toolsInstalled = @()
$toolsFailed = @()

# Define tools to install
$wingetTools = @(
    @{Id = "ajeetdsouza.zoxide"; Name = "zoxide"; Description = "Smart cd replacement" },
    @{Id = "junegunn.fzf"; Name = "fzf"; Description = "Fuzzy finder" },
    @{Id = "eza-community.eza"; Name = "eza"; Description = "Modern ls" },
    @{Id = "BurntSushi.ripgrep.MSVC"; Name = "rg"; Description = "Better grep" }
)

$scoopTools = @(
    @{Name = "bat"; Description = "Modern cat with syntax highlighting" },
    @{Name = "fd"; Description = "Better find" }
)

# Install via winget
if (Test-CommandExists 'winget') {
    Write-Host ""
    Write-Status "Installing tools via winget..." -Type Info
    foreach ($tool in $wingetTools) {
        if (Install-WingetPackage -Id $tool.Id -CommandName $tool.Name) {
            $toolsInstalled += $tool.Name
        } else {
            $toolsFailed += $tool.Name
            Write-Status "Will try scoop for $($tool.Name) if available" -Type Warning
        }
    }
} else {
    Write-Status "winget not available, will use scoop for all tools" -Type Warning
}

# Install via scoop (includes fallback for failed winget installs)
if (Test-CommandExists 'scoop') {
    Write-Host ""
    Write-Status "Installing tools via scoop..." -Type Info

    # Add tools from failed winget installs
    $allScoopTools = $scoopTools
    foreach ($failedTool in $toolsFailed) {
        $wingetTool = $wingetTools | Where-Object { $_.Name -eq $failedTool }
        if ($wingetTool -and $wingetTool.Name -in @('zoxide', 'fzf', 'eza', 'ripgrep')) {
            $scoopName = if ($failedTool -eq 'rg') { 'ripgrep' } else { $failedTool }
            $allScoopTools += @{Name = $scoopName; Description = $wingetTool.Description }
        }
    }

    foreach ($tool in $allScoopTools) {
        if (Install-ScoopPackage -Name $tool.Name) {
            $toolsInstalled += $tool.Name
        } else {
            Write-Status "Failed to install $($tool.Name)" -Type Warning
        }
    }
} else {
    Write-Status "Scoop not available, some tools could not be installed" -Type Warning
}

# ============================================================================
# 5. Install PowerShell Modules
# ============================================================================

Write-Host ""
Write-Status "Installing PowerShell modules..." -Type Info

$modules = @(
    @{Name = "PSFzf"; Description = "FZF integration for PowerShell (Ctrl+R, Ctrl+T)" }
)

foreach ($module in $modules) {
    if (Get-Module -ListAvailable -Name $module.Name) {
        Write-Status "$($module.Name) is already installed" -Type Success
    } else {
        Write-Status "Installing $($module.Name)..." -Type Info
        try {
            Install-Module $module.Name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Status "$($module.Name) installed successfully" -Type Success
        } catch {
            Write-Status "Failed to install $($module.Name): $_" -Type Warning
        }
    }
}

# ============================================================================
# 6. Install Tier 2 Tools (Development Tools)
# ============================================================================

Write-Host ""
Write-Status "Installing Tier 2 tools (development tools)..." -Type Info

# Define Tier 2 tools
$tier2WingetTools = @(
    @{Id = "JesseDuffield.Lazygit"; Name = "lazygit"; Description = "Git TUI" }
)

$tier2ScoopTools = @(
    @{Name = "delta"; Description = "Git diff viewer" },
    @{Name = "dust"; Description = "Disk usage analyzer" }
)

# Install via winget
if (Test-CommandExists 'winget') {
    foreach ($tool in $tier2WingetTools) {
        Install-WingetPackage -Id $tool.Id -CommandName $tool.Name | Out-Null
    }
}

# Install via scoop
if (Test-CommandExists 'scoop') {
    foreach ($tool in $tier2ScoopTools) {
        Install-ScoopPackage -Name $tool.Name | Out-Null
    }
}

# ============================================================================
# 7. Install Optional Tools (prompted)
# ============================================================================

Write-Host ""
Write-Status "Optional tools enhance your experience but aren't required." -Type Info

# Yazi - Modern terminal file manager
if (Confirm "Install yazi file manager? (Modern TUI file browser)" -DefaultYes $false) {
    Install-ScoopPackage "yazi" | Out-Null
}

# Tealdeer - Fast tldr client (command examples)
if (Confirm "Install tealdeer? (Quick command examples via 'tldr')" -DefaultYes $false) {
    Install-ScoopPackage "tealdeer" | Out-Null

    if (Test-CommandExists 'tldr') {
        Write-Status "Updating tealdeer cache..." -Type Info
        tldr --update 2>&1 | Out-Null
    }
}

# Glow - Markdown renderer (fixes incomplete feature)
if (Confirm "Install glow? (Beautiful markdown viewer)" -DefaultYes $false) {
    Install-ScoopPackage "glow" | Out-Null
}

# jq - JSON processor (essential for API/config work)
if (Confirm "Install jq? (JSON processor for parsing/filtering)" -DefaultYes $false) {
    $wingetSuccess = $false
    if (Test-CommandExists 'winget') {
        $wingetSuccess = Install-WingetPackage -Id "jqlang.jq" -CommandName "jq"
    }
    if (-not $wingetSuccess -and (Test-CommandExists 'scoop')) {
        Install-ScoopPackage "jq" | Out-Null
    }
}

# gsudo - sudo for Windows (elevate commands without new window)
if (Confirm "Install gsudo? (sudo for Windows - elevate commands)" -DefaultYes $false) {
    $wingetSuccess = $false
    if (Test-CommandExists 'winget') {
        $wingetSuccess = Install-WingetPackage -Id "gerardog.gsudo" -CommandName "gsudo"
    }
    if (-not $wingetSuccess -and (Test-CommandExists 'scoop')) {
        Install-ScoopPackage "gsudo" | Out-Null
    }
}

# ============================================================================
# 8. Install Nerd Font (JetBrainsMono)
# ============================================================================

Write-Host ""
if (Confirm "Install JetBrainsMono Nerd Font? (Required for icons)") {
    if (Test-CommandExists 'scoop') {
        Write-Status "Adding nerd-fonts bucket to scoop..." -Type Info
        scoop bucket add nerd-fonts 2>&1 | Out-Null

        Write-Status "Installing JetBrainsMono Nerd Font..." -Type Info
        scoop install JetBrainsMono-NF 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Status "JetBrainsMono Nerd Font installed successfully" -Type Success
            Write-Status "Note: You may need to restart Windows Terminal to see the font" -Type Info
        } else {
            Write-Status "Failed to install Nerd Font. You can install manually from https://www.nerdfonts.com/" -Type Warning
        }
    } else {
        Write-Status "Scoop not available. Install Nerd Font manually from https://www.nerdfonts.com/" -Type Warning
    }
} else {
    Write-Status "Skipping Nerd Font installation. Icons may not display correctly." -Type Info
}

# ============================================================================
# 9. Configure Windows Terminal (if installed)
# ============================================================================

Write-Host ""
$wtSettingsPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($wtSettingsPath) {
    Write-Status "Windows Terminal detected at: $($wtSettingsPath.FullName)" -Type Info

    if (Confirm "Add Tokyo Night theme to Windows Terminal?") {
        try {
            # Read current settings
            $wtSettings = Get-Content $wtSettingsPath.FullName -Raw | ConvertFrom-Json

            # Read our theme config
            $themeConfig = Get-Content (Join-Path $RepoDir "configs\windows-terminal.json") -Raw | ConvertFrom-Json

            # Add Tokyo Night scheme if it doesn't exist
            if (-not ($wtSettings.schemes | Where-Object { $_.name -eq "Tokyo Night" })) {
                if (-not $wtSettings.schemes) {
                    $wtSettings | Add-Member -MemberType NoteProperty -Name "schemes" -Value @() -Force
                }
                $wtSettings.schemes += $themeConfig.schemes[0]
                Write-Status "Added Tokyo Night color scheme" -Type Success
            } else {
                Write-Status "Tokyo Night scheme already exists" -Type Info
            }

            # Update default profile settings
            if (-not $wtSettings.profiles.defaults) {
                $wtSettings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value ([PSCustomObject]@{}) -Force
            }

            # Set color scheme
            $wtSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "colorScheme" -Value "Tokyo Night" -Force

            # Set font
            if (-not $wtSettings.profiles.defaults.font) {
                $wtSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{}) -Force
            }
            $wtSettings.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name "face" -Value "JetBrainsMono Nerd Font" -Force
            $wtSettings.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name "size" -Value 15 -Force

            # Set padding
            $wtSettings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "padding" -Value "10" -Force

            # Save settings
            $wtSettings | ConvertTo-Json -Depth 10 | Set-Content $wtSettingsPath.FullName -Force
            Write-Status "Windows Terminal configured with Tokyo Night theme" -Type Success
        } catch {
            Write-Status "Failed to configure Windows Terminal: $_" -Type Warning
            Write-Status "You can manually merge configs\windows-terminal.json into your settings" -Type Info
        }
    } else {
        Write-Status "Skipping Windows Terminal configuration" -Type Info
    }
} else {
    Write-Status "Windows Terminal not detected. Skipping theme configuration." -Type Info
    Write-Status "Install Windows Terminal: winget install Microsoft.WindowsTerminal" -Type Info
}

# ============================================================================
# 10. Configure Git to use Delta (optional)
# ============================================================================

Write-Host ""
if (Test-CommandExists 'git') {
    if (Test-CommandExists 'delta') {
        if (Confirm "Configure git to use delta for diffs?" -DefaultYes $false) {
            $deltaConfigPath = Join-Path $RepoDir "configs\delta.gitconfig"
            try {
                git config --global include.path $deltaConfigPath
                Write-Status "Git configured to use delta for diffs" -Type Success
            } catch {
                Write-Status "Failed to configure git delta: $_" -Type Warning
            }
        } else {
            Write-Status "Skipping delta git configuration" -Type Info
        }
    } else {
        Write-Status "Delta not installed, skipping git configuration" -Type Info
    }
} else {
    Write-Status "Git not found, skipping delta configuration" -Type Info
}

# ============================================================================
# 11. Deploy Configuration Files
# ============================================================================

Write-Host ""
Write-Status "Deploying configuration files..." -Type Info

# Create .config directory if it doesn't exist
$configDir = "$env:USERPROFILE\.config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Status "Created $configDir" -Type Success
}

# Copy starship.toml (overwrite if exists)
$starshipSource = Join-Path $RepoDir "configs\starship.toml"
$starshipDest = Join-Path $configDir "starship.toml"

Copy-Item $starshipSource $starshipDest -Force
Write-Status "Starship config deployed to $starshipDest" -Type Success

# ============================================================================
# 12. Setup PowerShell Profile
# ============================================================================

Write-Host ""
Write-Status "Setting up PowerShell profile..." -Type Info

# Ensure $PROFILE exists
if (-not (Test-Path $PROFILE)) {
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Status "Created new profile at $PROFILE" -Type Success
}

# Add hook to source our profile
$profileSource = Join-Path $RepoDir "scripts\profile.ps1"
$hookLine = ". `"$profileSource`""

$existingContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $existingContent -or $existingContent -notlike "*$profileSource*") {
    $hookComment = @"

# ============================================================================
# MyPowerShell Configuration
# ============================================================================
$hookLine
"@
    Add-Content -Path $PROFILE -Value $hookComment
    Write-Status "Added MyPowerShell hook to profile" -Type Success
} else {
    Write-Status "MyPowerShell hook already exists in profile" -Type Info
}

# ============================================================================
# 13. Installation Complete
# ============================================================================

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                               ║" -ForegroundColor Green
Write-Host "║                  Installation Complete! ✓                     ║" -ForegroundColor Green
Write-Host "║                                                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "What was installed:" -ForegroundColor Cyan
Write-Host "  Core Tools:" -ForegroundColor White
Write-Host "    • Starship prompt with Tokyo Night theme" -ForegroundColor Gray
Write-Host "    • Enhanced PSReadLine (history & predictions)" -ForegroundColor Gray
Write-Host "    • zoxide - Smart directory navigation (z/zi)" -ForegroundColor Gray
Write-Host "    • fzf + PSFzf - Fuzzy finder (Ctrl+R, Ctrl+T)" -ForegroundColor Gray
Write-Host "    • eza - Modern ls with icons (ls/ll/la/lt)" -ForegroundColor Gray
Write-Host "    • bat - Syntax-highlighted cat" -ForegroundColor Gray
Write-Host "    • fd - Fast file finder" -ForegroundColor Gray
Write-Host "    • ripgrep - Fast grep (rg)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Development Tools:" -ForegroundColor White
Write-Host "    • lazygit - Git TUI (lg)" -ForegroundColor Gray
Write-Host "    • delta - Beautiful git diffs" -ForegroundColor Gray
Write-Host "    • dust - Disk usage analyzer" -ForegroundColor Gray
Write-Host ""
Write-Host "  Optional Tools:" -ForegroundColor White
Write-Host "    • yazi - Terminal file manager (y)" -ForegroundColor Gray
Write-Host "    • tealdeer - Quick command examples (tldr)" -ForegroundColor Gray
Write-Host "    • glow - Markdown viewer" -ForegroundColor Gray
Write-Host "    • jq - JSON processor" -ForegroundColor Gray
Write-Host "    • gsudo - sudo for Windows" -ForegroundColor Gray
Write-Host ""
Write-Host "  Visual Enhancements:" -ForegroundColor White
Write-Host "    • JetBrainsMono Nerd Font (if installed)" -ForegroundColor Gray
Write-Host "    • Windows Terminal Tokyo Night theme (if configured)" -ForegroundColor Gray
Write-Host "    • ASCII art welcome banner" -ForegroundColor Gray
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart your terminal or run: " -ForegroundColor Gray -NoNewline
Write-Host ". `$PROFILE" -ForegroundColor Yellow
Write-Host "  2. See the ASCII art welcome banner on your next terminal" -ForegroundColor Gray
Write-Host "  3. Run 'tools' to view the full command reference guide" -ForegroundColor Gray
Write-Host "  4. Check out README.md for complete documentation" -ForegroundColor Gray
Write-Host ""
Write-Host "Profile location: $PROFILE" -ForegroundColor DarkGray
Write-Host ""
