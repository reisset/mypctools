#!/usr/bin/env bash
# mypctools/lib/distro-detect.sh
# Detect Linux distribution type
# v0.1.0

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        local os_id os_name os_id_like
        os_id=$(grep -m1 '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        os_name=$(grep -m1 '^NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
        os_id_like=$(grep -m1 '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')

        case "$os_id" in
            arch|manjaro|endeavouros|garuda|artix|cachyos)
                DISTRO_TYPE="arch"
                DISTRO_NAME="$os_name"
                ;;
            ubuntu|pop|debian|linuxmint|elementary|zorin)
                DISTRO_TYPE="debian"
                DISTRO_NAME="$os_name"
                ;;
            *)
                # Check ID_LIKE for derivatives (space-tokenized to avoid substring false-positives)
                if [[ " $os_id_like " == *" arch "* ]]; then
                    DISTRO_TYPE="arch"
                elif [[ " $os_id_like " == *" debian "* ]] || [[ " $os_id_like " == *" ubuntu "* ]]; then
                    DISTRO_TYPE="debian"
                else
                    DISTRO_TYPE="unknown"
                fi
                DISTRO_NAME="$os_name"
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
        *)
            # Fallback: detect by available commands; keep DISTRO_TYPE consistent.
            if command -v pacman &>/dev/null; then
                DISTRO_TYPE="arch"
                PKG_MGR="pacman"
                PKG_INSTALL="sudo pacman -S --noconfirm --needed"
                PKG_UPDATE="sudo pacman -Sy"
            elif command -v apt &>/dev/null; then
                DISTRO_TYPE="debian"
                PKG_MGR="apt"
                PKG_INSTALL="sudo apt install -y"
                PKG_UPDATE="sudo apt update"
            fi
            ;;
    esac

    export PKG_MGR PKG_INSTALL PKG_UPDATE

    if [[ -z "${PKG_INSTALL:-}" ]]; then
        echo -e "\033[0;31m[✗]\033[0m Unsupported distro '$DISTRO_NAME' — neither pacman nor apt found. Aborting." >&2
        exit 1
    fi
}

# Run detection on source
detect_distro
