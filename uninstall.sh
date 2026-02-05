#!/usr/bin/env bash
# mypctools uninstaller

INSTALL_DIR="$HOME/.local/share/mypctools"
BIN_PATH="$HOME/.local/bin/mypctools"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║        mypctools uninstaller          ║"
echo "╚═══════════════════════════════════════╝"
echo ""

echo "Removing mypctools..."

[[ -f "$BIN_PATH" ]] && rm "$BIN_PATH" && echo "  Removed binary"
[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR" && echo "  Removed $INSTALL_DIR"

echo ""
echo "Done. mypctools has been uninstalled."
echo ""
