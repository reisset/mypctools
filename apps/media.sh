#!/usr/bin/env bash
# mypctools/apps/media.sh
# Media apps installation menu
# v0.1.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/helpers.sh"
source "$SCRIPT_DIR/../lib/package-manager.sh"

show_media_menu() {
    print_header "Media"

    local choices
    choices=$(gum choose --no-limit --header "Select media apps to install:" \
        "Spotify" \
        "VLC" \
        "MPV" \
        "Back")

    if [[ -z "$choices" ]] || [[ "$choices" == "Back" ]]; then
        return
    fi

    echo ""
    print_header "Would install the following:"
    echo "$choices" | while read -r choice; do
        [[ "$choice" != "Back" ]] && print_info "$choice"
    done
    echo ""

    gum confirm "Proceed with installation?" && {
        echo "$choices" | while read -r choice; do
            case "$choice" in
                "Spotify")
                    install_package "Spotify" "spotify-client" "spotify" "com.spotify.Client" ""
                    ;;
                "VLC")
                    install_package "VLC" "vlc" "vlc" "org.videolan.VLC" ""
                    ;;
                "MPV")
                    install_package "MPV" "mpv" "mpv" "io.mpv.Mpv" ""
                    ;;
            esac
        done
        print_success "Done!"
        read -rp "Press Enter to continue..."
    }
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_media_menu
fi
