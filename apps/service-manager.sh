#!/usr/bin/env bash
# mypctools/apps/service-manager.sh
# TUI for managing systemd services
# v0.4.0

_SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SERVICE_DIR/../lib/helpers.sh"
source "$_SERVICE_DIR/../lib/theme.sh"

# Common services to manage
SERVICES=(
    "docker"
    "ssh"
    "sshd"
    "bluetooth"
    "cups"
    "NetworkManager"
    "avahi-daemon"
    "cron"
    "ufw"
    "firewalld"
)

# Get service status indicator
get_service_status() {
    local service="$1"
    local is_active is_enabled

    is_active=$(systemctl is-active "$service" 2>/dev/null)
    is_enabled=$(systemctl is-enabled "$service" 2>/dev/null)

    if [[ "$is_active" == "active" ]]; then
        echo "●"  # Running
    elif [[ "$is_enabled" == "enabled" ]]; then
        echo "◐"  # Enabled but not running
    else
        echo "○"  # Stopped/disabled
    fi
}

# Build service list with status
build_service_list() {
    local available_services=()
    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files "$service.service" &>/dev/null; then
            local status
            status=$(get_service_status "$service")
            available_services+=("$status $service")
        fi
    done
    printf '%s\n' "${available_services[@]}"
}

# Show action menu for a service
show_service_actions() {
    local service="$1"

    while true; do
        clear
        show_subheader "Service: $service"

        local is_active is_enabled
        is_active=$(systemctl is-active "$service" 2>/dev/null)
        is_enabled=$(systemctl is-enabled "$service" 2>/dev/null)

        print_info "Status: $is_active"
        print_info "Enabled: $is_enabled"
        echo ""

        local action
        action=$(themed_choose "" \
            "Start" \
            "Stop" \
            "Restart" \
            "Enable" \
            "Disable" \
            "View Status" \
            "Back")

        case "$action" in
            "Start")
                ensure_sudo || continue
                if sudo systemctl start "$service"; then
                    print_success "Started $service"
                else
                    print_error "Failed to start $service"
                fi
                read -rp "Press Enter to continue..."
                clear
                ;;
            "Stop")
                ensure_sudo || continue
                if sudo systemctl stop "$service"; then
                    print_success "Stopped $service"
                else
                    print_error "Failed to stop $service"
                fi
                read -rp "Press Enter to continue..."
                clear
                ;;
            "Restart")
                ensure_sudo || continue
                if sudo systemctl restart "$service"; then
                    print_success "Restarted $service"
                else
                    print_error "Failed to restart $service"
                fi
                read -rp "Press Enter to continue..."
                clear
                ;;
            "Enable")
                ensure_sudo || continue
                if sudo systemctl enable "$service"; then
                    print_success "Enabled $service"
                else
                    print_error "Failed to enable $service"
                fi
                read -rp "Press Enter to continue..."
                clear
                ;;
            "Disable")
                ensure_sudo || continue
                if sudo systemctl disable "$service"; then
                    print_success "Disabled $service"
                else
                    print_error "Failed to disable $service"
                fi
                read -rp "Press Enter to continue..."
                clear
                ;;
            "View Status")
                clear
                systemctl status "$service" --no-pager || true
                echo ""
                read -rp "Press Enter to continue..."
                clear
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

# Main service manager menu
show_service_manager() {
    while true; do
        clear
        show_subheader "Service Manager"
        print_info "● running  ◐ enabled/stopped  ○ stopped"
        echo ""

        local services_list
        services_list=$(build_service_list)

        if [[ -z "$services_list" ]]; then
            print_warning "No known services found on this system."
            read -rp "Press Enter to continue..."
            return
        fi

        local choice
        choice=$(echo -e "$services_list\nBack" | gum choose \
            --cursor.foreground="$THEME_PRIMARY" \
            --item.foreground="$THEME_SECONDARY" \
            --selected.foreground="$THEME_PRIMARY")

        if [[ "$choice" == "Back" || -z "$choice" ]]; then
            break
        fi

        # Extract service name (remove status indicator)
        local service_name
        service_name=$(echo "$choice" | sed 's/^[●◐○] //')
        show_service_actions "$service_name"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_service_manager
fi
