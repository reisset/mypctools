#!/usr/bin/env bash
# mypctools/apps/media.sh
# Media apps installation menu
# v0.2.0

_MEDIA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_MEDIA_DIR/../lib/helpers.sh"
source "$_MEDIA_DIR/../lib/theme.sh"
source "$_MEDIA_DIR/../lib/package-manager.sh"

show_media_menu() {
    clear
    show_subheader "Media" "Install Apps >"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "$(app_label "Discord" "discord" "" "com.discordapp.Discord")" \
        "$(app_label "Spotify" "spotify" "spotify-client" "com.spotify.Client")" \
        "$(app_label "VLC" "vlc" "vlc" "org.videolan.VLC")" \
        "$(app_label "MPV" "mpv" "mpv" "io.mpv.Mpv")")

    if [[ -z "$choices" ]]; then
        return
    fi

    # Build preview list (strip badge for display and matching)
    local preview_items=()
    while read -r choice; do
        choice="${choice%  ✓}"
        preview_items+=("$choice")
    done <<< "$choices"
    show_preview_box "Selected for installation:" "${preview_items[@]}"
    echo ""

    if themed_confirm "Proceed with installation?"; then
        local total=${#preview_items[@]} current=0 succeeded=0 failed=0
        while read -r choice; do
            choice="${choice%  ✓}"
            ((current++))
            print_info "[$current/$total] $choice"
            case "$choice" in
                "Discord")
                    install_package "Discord" "" "discord" "com.discordapp.Discord" "install_discord_fallback"
                    ;;
                "Spotify")
                    install_package "Spotify" "spotify-client" "spotify" "com.spotify.Client" "install_spotify_fallback"
                    ;;
                "VLC")
                    install_package "VLC" "vlc" "vlc" "org.videolan.VLC" ""
                    ;;
                "MPV")
                    install_package "MPV" "mpv" "mpv" "io.mpv.Mpv" ""
                    ;;
            esac
            [[ $? -eq 0 ]] && ((succeeded++)) || ((failed++))
        done <<< "$choices"
        show_install_summary $succeeded $failed $total
        notify_done "mypctools" "$succeeded/$total media apps installed"
        themed_pause
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_media_menu
fi
