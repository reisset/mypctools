#!/usr/bin/env bash
# mypctools/apps/service-manager.sh
# TUI for managing systemd services
# v0.12.0

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
                    log_action "service start $service: success"
                else
                    print_error "Failed to start $service"
                    log_action "service start $service: failed"
                fi
                themed_pause
                ;;
            "Stop")
                ensure_sudo || continue
                if sudo systemctl stop "$service"; then
                    print_success "Stopped $service"
                    log_action "service stop $service: success"
                else
                    print_error "Failed to stop $service"
                    log_action "service stop $service: failed"
                fi
                themed_pause
                ;;
            "Restart")
                ensure_sudo || continue
                if sudo systemctl restart "$service"; then
                    print_success "Restarted $service"
                    log_action "service restart $service: success"
                else
                    print_error "Failed to restart $service"
                    log_action "service restart $service: failed"
                fi
                themed_pause
                ;;
            "Enable")
                ensure_sudo || continue
                if sudo systemctl enable "$service"; then
                    print_success "Enabled $service"
                    log_action "service enable $service: success"
                else
                    print_error "Failed to enable $service"
                    log_action "service enable $service: failed"
                fi
                themed_pause
                ;;
            "Disable")
                ensure_sudo || continue
                if sudo systemctl disable "$service"; then
                    print_success "Disabled $service"
                    log_action "service disable $service: success"
                else
                    print_error "Failed to disable $service"
                    log_action "service disable $service: failed"
                fi
                themed_pause
                ;;
            "View Status")
                clear
                show_subheader "Service Status: $service" "Service Manager >"
                systemctl status "$service" --no-pager 2>&1 | themed_pager
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

# Browse common services via gum table
browse_common_services() {
    while true; do
        clear
        show_subheader "Common Services" "Service Manager >"

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

# Browse all system services via gum filter
browse_all_services() {
    while true; do
        clear
        show_subheader "All Services" "Service Manager >"

        local services
        services=$(systemctl list-unit-files --type=service --no-pager --no-legend \
            | awk '{print $1}' | sed 's/\.service$//' | sort)

        if [[ -z "$services" ]]; then
            print_warning "No services found."
            themed_pause
            return
        fi

        local choice
        choice=$(echo "$services" | gum filter --placeholder "Search services...")

        if [[ -z "$choice" ]]; then
            break
        fi

        show_service_actions "$choice"
    done
}

# Main service manager menu
show_service_manager() {
    while true; do
        clear
        show_subheader "Service Manager" "System Setup >"

        local choice
        choice=$(themed_choose "" \
            "$ICON_SERVICE  Common Services" \
            "All Services" \
            "$ICON_BACK  Back")

        case "$choice" in
            *"Common Services")
                browse_common_services
                ;;
            "All Services")
                browse_all_services
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
