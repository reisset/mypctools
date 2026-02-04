#!/usr/bin/env bash
# mypctools/launcher.sh
# Main TUI launcher for mypctools
# v0.6.0

MYPCTOOLS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$MYPCTOOLS_ROOT/lib/helpers.sh"
source "$MYPCTOOLS_ROOT/lib/theme.sh"
source "$MYPCTOOLS_ROOT/lib/distro-detect.sh"

VERSION="0.6.0"
UPDATE_AVAILABLE=""

read -r -d '' LOGO <<'LOGOEOF'
███╗   ███╗██╗   ██╗██████╗  ██████╗████████╗ ██████╗  ██████╗ ██╗     ███████╗
████╗ ████║╚██╗ ██╔╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
██╔████╔██║ ╚████╔╝ ██████╔╝██║        ██║   ██║   ██║██║   ██║██║     ███████╗
██║╚██╔╝██║  ╚██╔╝  ██╔═══╝ ██║        ██║   ██║   ██║██║   ██║██║     ╚════██║
██║ ╚═╝ ██║   ██║   ██║     ╚██████╗   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
╚═╝     ╚═╝   ╚═╝   ╚═╝      ╚═════╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
LOGOEOF

# Cleanup on interrupt
cleanup() {
    tput cnorm 2>/dev/null  # Show cursor
    stty echo 2>/dev/null   # Re-enable echo
    echo ""
    exit 130
}
trap cleanup SIGINT SIGTERM

# Don't run as root
if check_root; then
    print_error "Do not run as root. Use your normal user."
    exit 1
fi

# Check gum is installed
if ! command_exists gum; then
    print_error "gum is not installed. Run ./install.sh first."
    exit 1
fi

# Silent version check (runs in background)
check_for_updates() {
    if [[ -d "$MYPCTOOLS_ROOT/.git" ]]; then
        if timeout 3 git -C "$MYPCTOOLS_ROOT" fetch origin main &>/dev/null; then
            local behind
            behind=$(git -C "$MYPCTOOLS_ROOT" rev-list HEAD..origin/main --count 2>/dev/null)
            [[ -n "$behind" && "$behind" -gt 0 ]] && UPDATE_AVAILABLE="$behind"
        fi
    fi
}

# ASCII logo with version
show_logo() {
    sleep 0.5  # Wait for background update check
    gum style --foreground "$THEME_PRIMARY" --align center "$LOGO"
    local version_line="v$VERSION"
    if [[ -n "$UPDATE_AVAILABLE" ]]; then
        version_line="v$VERSION  •  ⬆ Update available ($UPDATE_AVAILABLE new)"
    fi
    gum style --foreground "$THEME_MUTED" --align center "$version_line"
    local sys_line="$DISTRO_NAME · $(uname -r) · $(basename "$SHELL")"
    gum style --foreground "$THEME_MUTED" --align center "$sys_line"
    echo
}

# Start background update check
check_for_updates &

# Submenus
show_install_apps_menu() {
    while true; do
        clear
        show_subheader "Install Apps"
        local choice
        choice=$(themed_choose "" \
            "AI" \
            "Browsers" \
            "Gaming" \
            "Media" \
            "Dev Tools" \
            "Back")

        case "$choice" in
            "AI")
                source "$MYPCTOOLS_ROOT/apps/ai.sh"
                show_ai_menu
                ;;
            "Browsers")
                source "$MYPCTOOLS_ROOT/apps/browsers.sh"
                show_browsers_menu
                ;;
            "Gaming")
                source "$MYPCTOOLS_ROOT/apps/gaming.sh"
                show_gaming_menu
                ;;
            "Media")
                source "$MYPCTOOLS_ROOT/apps/media.sh"
                show_media_menu
                ;;
            "Dev Tools")
                source "$MYPCTOOLS_ROOT/apps/dev-tools.sh"
                show_dev_tools_menu
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_script_submenu() {
    local script_dir="$1"
    local subheader_text="$2"

    while true; do
        clear
        show_subheader "$subheader_text" "My Scripts >"
        local action
        action=$(themed_choose "" \
            "Install" \
            "Uninstall" \
            "Back")

        case "$action" in
            "Install")
                if [[ -f "$MYPCTOOLS_ROOT/scripts/$script_dir/install.sh" ]]; then
                    bash "$MYPCTOOLS_ROOT/scripts/$script_dir/install.sh"
                else
                    print_warning "Install script not found."
                fi
                themed_pause
                ;;
            "Uninstall")
                if [[ -f "$MYPCTOOLS_ROOT/scripts/$script_dir/uninstall.sh" ]]; then
                    bash "$MYPCTOOLS_ROOT/scripts/$script_dir/uninstall.sh"
                else
                    print_warning "Uninstall script not found."
                fi
                themed_pause
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_scripts_menu() {
    while true; do
        clear
        show_subheader "My Scripts"
        local choice
        choice=$(themed_choose "" \
            "Claude Setup" \
            "Spicetify Theme" \
            "LiteBash" \
            "LiteZsh" \
            "Terminal - foot" \
            "Terminal - alacritty" \
            "Terminal - ghostty" \
            "Terminal - kitty" \
            "Fastfetch" \
            "Screensaver" \
            "Back")

        case "$choice" in
            "Claude Setup")       show_script_submenu "claude" "Claude Setup" ;;
            "Spicetify Theme")    show_script_submenu "spicetify" "Spicetify Theme" ;;
            "LiteBash")           show_script_submenu "litebash" "LiteBash" ;;
            "LiteZsh")            show_script_submenu "litezsh" "LiteZsh" ;;
            "Terminal - foot")    show_script_submenu "terminal" "Terminal - foot (Wayland)" ;;
            "Terminal - alacritty") show_script_submenu "alacritty" "Terminal - alacritty" ;;
            "Terminal - ghostty") show_script_submenu "ghostty" "Terminal - ghostty" ;;
            "Terminal - kitty")   show_script_submenu "kitty" "Terminal - kitty" ;;
            "Fastfetch")          show_script_submenu "fastfetch" "Fastfetch" ;;
            "Screensaver")        show_script_submenu "screensaver" "Screensaver" ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_system_setup_menu() {
    while true; do
        clear
        show_subheader "System Setup"
        local choice
        choice=$(themed_choose "" \
            "Full System Update" \
            "System Cleanup" \
            "Service Manager" \
            "System Info" \
            "Back")

        case "$choice" in
            "Full System Update")
                ensure_sudo || continue
                local update_failed=0
                echo ""
                gum style --foreground "$THEME_MUTED" "─────────────────────────────────────────"
                echo ""
                case "$DISTRO_TYPE" in
                    debian)
                        print_info "Updating package lists..."
                        if sudo apt update; then
                            echo ""
                            print_info "Upgrading packages..."
                            sudo apt upgrade -y || update_failed=1
                        else
                            update_failed=1
                        fi
                        ;;
                    arch)
                        print_info "Syncing and upgrading packages..."
                        sudo pacman -Syu --noconfirm || update_failed=1
                        ;;
                    fedora)
                        print_info "Upgrading packages..."
                        sudo dnf upgrade -y || update_failed=1
                        ;;
                    *)
                        print_error "Unsupported distro type: $DISTRO_TYPE"
                        update_failed=1
                        ;;
                esac
                echo ""
                gum style --foreground "$THEME_MUTED" "─────────────────────────────────────────"
                echo ""
                if [[ "$update_failed" -eq 1 ]]; then
                    print_error "System update finished with errors (see output above)"
                else
                    print_success "System update complete"
                fi
                echo ""
                themed_pause
                clear
                ;;
            "System Cleanup")
                ensure_sudo || continue
                print_info "Running system cleanup..."
                case "$DISTRO_TYPE" in
                    debian)
                        themed_spin "$SPINNER_CLEANUP" "Removing unused packages..." sudo apt autoremove -y
                        themed_spin "$SPINNER_CLEANUP" "Cleaning package cache..." sudo apt autoclean
                        themed_spin "$SPINNER_CLEANUP" "Clearing apt cache..." sudo apt clean
                        ;;
                    arch)
                        orphans=$(pacman -Qtdq 2>/dev/null)
                        if [[ -n "$orphans" ]]; then
                            echo "$orphans"
                            if themed_confirm "Remove these orphan packages?"; then
                                themed_spin "$SPINNER_CLEANUP" "Removing orphans..." bash -c 'echo "$1" | sudo pacman -Rns --noconfirm -' _ "$orphans"
                            fi
                        fi
                        if command_exists paccache; then
                            themed_spin "$SPINNER_CLEANUP" "Clearing package cache..." sudo paccache -rk2
                        else
                            themed_spin "$SPINNER_CLEANUP" "Clearing package cache..." sudo pacman -Sc --noconfirm
                        fi
                        ;;
                    fedora)
                        themed_spin "$SPINNER_CLEANUP" "Removing unused packages..." sudo dnf autoremove -y
                        themed_spin "$SPINNER_CLEANUP" "Cleaning dnf cache..." sudo dnf clean all
                        ;;
                    *)
                        print_error "Unsupported distro type: $DISTRO_TYPE"
                        ;;
                esac
                # User caches (all distros)
                if themed_confirm "Clear user caches (thumbnails, trash)?"; then
                    themed_spin "$SPINNER_CLEANUP" "Clearing user caches..." bash -c 'rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null; rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null'
                fi
                print_success "Cleanup complete"
                themed_pause
                clear
                ;;
            "Service Manager")
                source "$MYPCTOOLS_ROOT/apps/service-manager.sh"
                show_service_manager
                ;;
            "System Info")
                clear
                show_subheader "System Information" "System Setup >"

                # Build info lines
                local info_lines=""
                info_lines+="  User       $USER@$(hostname)"$'\n'
                info_lines+="  OS         $DISTRO_NAME"$'\n'

                # Host (hardware model)
                local host_model=""
                [[ -f /sys/devices/virtual/dmi/id/product_name ]] && host_model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)
                [[ -n "$host_model" ]] && info_lines+="  Host       $host_model"$'\n'

                info_lines+="  Kernel     $(uname -r)"$'\n'

                # Uptime
                local uptime_str
                uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')
                [[ -n "$uptime_str" ]] && info_lines+="  Uptime     $uptime_str"$'\n'

                # Packages
                local pkg_count=""
                if command_exists dpkg; then
                    pkg_count="$(dpkg --get-selections 2>/dev/null | wc -l) (dpkg)"
                elif command_exists pacman; then
                    pkg_count="$(pacman -Q 2>/dev/null | wc -l) (pacman)"
                fi
                if command_exists flatpak; then
                    local flatpak_count
                    flatpak_count=$(flatpak list --app 2>/dev/null | wc -l)
                    [[ -n "$pkg_count" ]] && pkg_count="$pkg_count + $flatpak_count (flatpak)" || pkg_count="$flatpak_count (flatpak)"
                fi
                [[ -n "$pkg_count" ]] && info_lines+="  Packages   $pkg_count"$'\n'

                info_lines+="  Shell      $(basename "$SHELL")"$'\n'
                [[ -n "$XDG_CURRENT_DESKTOP" ]] && info_lines+="  DE         $XDG_CURRENT_DESKTOP"$'\n'
                [[ -n "$XDG_SESSION_TYPE" ]] && info_lines+="  Session    $XDG_SESSION_TYPE"$'\n'
                [[ -n "$TERM" ]] && info_lines+="  Terminal   $TERM"$'\n'

                # CPU
                local cpu_model
                cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //')
                [[ -n "$cpu_model" ]] && info_lines+="  CPU        $cpu_model"$'\n'

                # GPU
                local gpu_info
                gpu_info=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | sed 's/.*: //')
                [[ -n "$gpu_info" ]] && info_lines+="  GPU        $gpu_info"$'\n'

                # Memory
                local mem_total mem_used
                mem_total=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{printf "%.1f", $2/1024/1024}')
                mem_used=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%.1f", $3/1024}')
                [[ -n "$mem_total" ]] && info_lines+="  Memory     ${mem_used}GB / ${mem_total}GB"$'\n'

                # Disk
                local disk_info
                disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')
                [[ -n "$disk_info" ]] && info_lines+="  Disk (/)   $disk_info"$'\n'

                # Display in styled box
                info_lines="${info_lines%$'\n'}"  # Remove trailing newline
                gum style \
                    --border rounded \
                    --border-foreground "$THEME_SECONDARY" \
                    --foreground "$THEME_PRIMARY" \
                    --padding "1 2" \
                    "$info_lines"

                echo ""
                themed_pause
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        clear
        show_logo

        # Build menu options (add Pull Updates if available)
        local menu_options=("Install Apps" "My Scripts" "System Setup")
        if [[ -n "$UPDATE_AVAILABLE" ]]; then
            menu_options+=("⬆ Pull Updates")
        fi
        menu_options+=("Exit")

        local choice
        choice=$(themed_choose "" "${menu_options[@]}")

        case "$choice" in
            "Install Apps")
                show_install_apps_menu
                ;;
            "My Scripts")
                show_scripts_menu
                ;;
            "System Setup")
                show_system_setup_menu
                ;;
            "⬆ Pull Updates")
                clear
                show_subheader "Pull Updates" "System Setup >"
                if git -C "$MYPCTOOLS_ROOT" pull origin main; then
                    print_success "Updated! Restart mypctools to use new version."
                else
                    print_error "Failed to pull updates"
                fi
                UPDATE_AVAILABLE=""
                themed_pause
                ;;
            "Exit"|"")
                print_success "Goodbye!"
                exit 0
                ;;
        esac
    done
}

# CLI flags
case "${1:-}" in
    --help|-h)
        echo "mypctools v$VERSION"
        echo "A personal TUI for managing scripts and apps"
        echo "Built with Gum by Charm"
        echo ""
        echo "Usage: mypctools [option]"
        echo ""
        echo "Options:"
        echo "  --help, -h       Show this help message"
        echo "  --version, -v    Show version number"
        echo ""
        echo "https://github.com/reisset/mypctools"
        exit 0
        ;;
    --version|-v)
        echo "mypctools v$VERSION"
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run 'mypctools --help' for usage."
        exit 1
        ;;
esac

# Run
main_menu
