#!/usr/bin/env bash
# mypctools/apps/service-manager.sh
# TUI for managing systemd services
# v0.5.0

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
    "crond"
    "ufw"
    "firewalld"
)

# Build CSV for gum table
build_service_csv() {
    echo "Service,Status,Enabled"
    for service in "${SERVICES[@]}"; do
        if systemctl list-unit-files "${service}.service" &>/dev/null; then
            local is_active is_enabled
            is_active=$(systemctl is-active "$service" 2>/dev/null)
            is_enabled=$(systemctl is-enabled "$service" 2>/dev/null)
            echo "$service,$is_active,$is_enabled"
        fi
    done
}

# Show action menu for a service
show_service_actions() {
    local service="$1"

    while true; do
        clear
        show_subheader "Service: $service" "Service Manager >"

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
                themed_pause
                clear
                ;;
            "Stop")
                ensure_sudo || continue
                if sudo systemctl stop "$service"; then
                    print_success "Stopped $service"
                else
                    print_error "Failed to stop $service"
                fi
                themed_pause
                clear
                ;;
            "Restart")
                ensure_sudo || continue
                if sudo systemctl restart "$service"; then
                    print_success "Restarted $service"
                else
                    print_error "Failed to restart $service"
                fi
                themed_pause
                clear
                ;;
            "Enable")
                ensure_sudo || continue
                if sudo systemctl enable "$service"; then
                    print_success "Enabled $service"
                else
                    print_error "Failed to enable $service"
                fi
                themed_pause
                clear
                ;;
            "Disable")
                ensure_sudo || continue
                if sudo systemctl disable "$service"; then
                    print_success "Disabled $service"
                else
                    print_error "Failed to disable $service"
                fi
                themed_pause
                clear
                ;;
            "View Status")
                clear
                show_subheader "Service Status: $service" "Service Manager >"
                systemctl status "$service" --no-pager 2>&1 | themed_pager
                clear
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

# Browse known services via gum table
browse_services() {
    while true; do
        clear
        show_subheader "Browse Services" "Service Manager >"

        local csv_data
        csv_data=$(build_service_csv)

        local line_count
        line_count=$(echo "$csv_data" | wc -l)

        if [[ "$line_count" -le 1 ]]; then
            print_warning "No known services found on this system."
            themed_pause
            return
        fi

        local choice
        choice=$(echo "$csv_data" | gum table \
            --return-column 1 \
            --widths 20,12,12 \
            --height 16)

        if [[ -z "$choice" ]]; then
            break
        fi

        show_service_actions "$choice"
    done
}

# Enter a custom service name via gum input
enter_custom_service() {
    clear
    show_subheader "Custom Service" "Service Manager >"

    local service_name
    service_name=$(gum input \
        --placeholder "e.g., nginx, postgresql..." \
        --prompt "> " --prompt.foreground "$THEME_PRIMARY" \
        --header "Enter service name:" --header.foreground "$THEME_MUTED")

    if [[ -z "$service_name" ]]; then
        return
    fi

    # Validate that the service exists
    if ! systemctl list-unit-files "${service_name}.service" &>/dev/null; then
        print_error "Service '${service_name}' not found"
        print_info "Check the name with: systemctl list-unit-files '*${service_name}*'"
        themed_pause
        return
    fi

    show_service_actions "$service_name"
}

# Main service manager menu
show_service_manager() {
    while true; do
        clear
        show_subheader "Service Manager" "System Setup >"

        local choice
        choice=$(themed_choose "" \
            "$ICON_SERVICE  Browse Services" \
            "Enter Custom Service" \
            "$ICON_BACK  Back")

        case "$choice" in
            *"Browse Services")
                browse_services
                ;;
            "Enter Custom Service")
                enter_custom_service
                ;;
            *"Back"|"")
                break
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_service_manager
fi
