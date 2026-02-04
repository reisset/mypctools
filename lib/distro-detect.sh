#!/usr/bin/env bash
# mypctools/lib/distro-detect.sh
# Detect Linux distribution type
# v0.1.0

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # Save LOGO before sourcing (Arch's os-release sets LOGO=archlinux-logo)
        local _saved_logo="${LOGO:-}"
        source /etc/os-release
        [[ -n "$_saved_logo" ]] && LOGO="$_saved_logo"

        case "$ID" in
            arch|manjaro|endeavouros|garuda|artix|cachyos)
                DISTRO_TYPE="arch"
                DISTRO_NAME="$NAME"
                ;;
            ubuntu|pop|debian|linuxmint|elementary|zorin)
                DISTRO_TYPE="debian"
                DISTRO_NAME="$NAME"
                ;;
            fedora|rhel|centos|rocky|alma)
                DISTRO_TYPE="fedora"
                DISTRO_NAME="$NAME"
                ;;
            *)
                # Check ID_LIKE for derivatives
                if [[ "$ID_LIKE" == *"arch"* ]]; then
                    DISTRO_TYPE="arch"
                elif [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID_LIKE" == *"ubuntu"* ]]; then
                    DISTRO_TYPE="debian"
                elif [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID_LIKE" == *"rhel"* ]]; then
                    DISTRO_TYPE="fedora"
                else
                    DISTRO_TYPE="unknown"
                fi
                DISTRO_NAME="$NAME"
                ;;
        esac
    else
        DISTRO_TYPE="unknown"
        DISTRO_NAME="Unknown"
    fi

    export DISTRO_TYPE
    export DISTRO_NAME

    # Set package manager commands based on distro type (with fallback)
    case "$DISTRO_TYPE" in
        arch)
            PKG_MGR="pacman"
            PKG_INSTALL="sudo pacman -S --noconfirm --needed"
            PKG_UPDATE="sudo pacman -Sy"
            ;;
        debian)
            PKG_MGR="apt"
            PKG_INSTALL="sudo apt install -y"
            PKG_UPDATE="sudo apt update"
            ;;
        fedora)
            PKG_MGR="dnf"
            PKG_INSTALL="sudo dnf install -y"
            PKG_UPDATE="sudo dnf check-update || true"
            ;;
        *)
            # Fallback: detect by available commands
            if command -v pacman &>/dev/null; then
                PKG_MGR="pacman"
                PKG_INSTALL="sudo pacman -S --noconfirm --needed"
                PKG_UPDATE="sudo pacman -Sy"
            elif command -v apt &>/dev/null; then
                PKG_MGR="apt"
                PKG_INSTALL="sudo apt install -y"
                PKG_UPDATE="sudo apt update"
            elif command -v dnf &>/dev/null; then
                PKG_MGR="dnf"
                PKG_INSTALL="sudo dnf install -y"
                PKG_UPDATE="sudo dnf check-update || true"
            fi
            ;;
    esac

    export PKG_MGR PKG_INSTALL PKG_UPDATE

    if [[ "$DISTRO_TYPE" == "unknown" ]]; then
        echo -e "\033[33mWarning: Unrecognized distro '$DISTRO_NAME'. Package installation may not work.\033[0m" >&2
    fi
}

# Run detection on source
detect_distro
