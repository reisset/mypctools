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
    show_subheader "Media"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "Spotify" \
        "VLC" \
        "MPV")

    if [[ -z "$choices" ]]; then
        return
    fi

    echo ""
    show_subheader "Would install"
    while read -r choice; do
        print_info "$choice"
    done <<< "$choices"
    echo ""

    if themed_confirm "Proceed with installation?"; then
        while read -r choice; do
            case "$choice" in
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
        done <<< "$choices"
        print_success "Done!"
        read -rp "Press Enter to continue..."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_media_menu
fi
