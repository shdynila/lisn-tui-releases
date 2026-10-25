#!/usr/bin/env bash
set -e

# ==============================================================================
# LISN-TUI Universal Runner & Installer
# Automatically installs, updates, and launches LISN-TUI on Linux and macOS.
# ==============================================================================

REPO="shdynila/lisn-tui-releases"
INSTALL_DIR="${HOME}/.lisn-tui/bin"
BIN_PATH="${INSTALL_DIR}/lisn"
VERSION_FILE="${INSTALL_DIR}/version.txt"

# Check if running inside bare Termux (Android)
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
    echo "================================================================="
    echo "📱 Android Termux Environment Detected!"
    echo "================================================================="
    echo "For optimal performance, glibc compatibility, and phone audio routing,"
    echo "LISN-TUI runs with PulseAudio inside PRoot."
    echo ""
    echo "Switching to automated Termux launcher..."
    curl -sSL "https://raw.githubusercontent.com/${REPO}/main/termux.sh" | bash -s -- "$@"
    exit $?
fi

echo "🔍 Checking for latest LISN-TUI release..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)

if [ -z "$LATEST_TAG" ]; then
    echo "⚠️  Could not reach GitHub Releases API. Checking local installation..."
    if [ -x "$BIN_PATH" ]; then
        echo "Launching installed version..."
        exec "$BIN_PATH" "$@"
    else
        echo "❌ No installed binary found and cannot reach GitHub API. Check your internet connection."
        exit 1
    fi
fi

CURRENT_TAG=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_TAG=$(cat "$VERSION_FILE" 2>/dev/null || true)
fi

# Detect Operating System and Architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        case "$ARCH" in
            x86_64|amd64)
                ASSET_NAME="lisn_linux_amd64.tar.gz"
                ;;
            aarch64|arm64)
                ASSET_NAME="lisn_linux_arm64.tar.gz"
                ;;
            *)
                echo "❌ Unsupported Linux architecture: $ARCH"
                exit 1
                ;;
        esac
        ;;
    Darwin)
        case "$ARCH" in
            arm64)
                ASSET_NAME="lisn_mac_silicon.tar.gz"
                ;;
            x86_64|amd64)
                ASSET_NAME="lisn_mac_intel.tar.gz"
                ;;
            *)
                echo "❌ Unsupported macOS architecture: $ARCH"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "❌ Unsupported operating system: $OS"
        echo "For Windows, use: irm https://raw.githubusercontent.com/${REPO}/main/run.ps1 | iex"
        exit 1
        ;;
esac

# If up to date and executable, launch immediately
if [ -x "$BIN_PATH" ] && [ "$CURRENT_TAG" = "$LATEST_TAG" ]; then
    exec "$BIN_PATH" "$@"
fi

echo "📥 Installing / Updating LISN-TUI (${LATEST_TAG}) for ${OS} (${ARCH})..."
mkdir -p "$INSTALL_DIR"

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
TMP_TAR="${INSTALL_DIR}/lisn_update.tar.gz"

curl -f -sSL -o "$TMP_TAR" "$DOWNLOAD_URL" || {
    echo "❌ Failed to download release asset from: $DOWNLOAD_URL"
    exit 1
}

tar -xzf "$TMP_TAR" -C "$INSTALL_DIR"
rm -f "$TMP_TAR"

chmod +x "$BIN_PATH"
echo "$LATEST_TAG" > "$VERSION_FILE"

echo "✅ LISN-TUI ${LATEST_TAG} installed successfully in ${INSTALL_DIR}"
echo ""

# Launch
exec "$BIN_PATH" "$@"
