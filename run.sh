#!/usr/bin/env bash
set -e

# ==============================================================================
# LISN-TUI Universal Bash Runner & Installer
# Works on Linux, macOS, and Android (Termux).
# ==============================================================================

REPO="shdynila/lisn-tui-releases"

# 1. Android Termux Detection & Automated Bootstrap
if ([ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]) && [ ! -f "/etc/proot" ]; then
    echo "================================================================="
    echo "📱 Android Termux Environment Detected!"
    echo "================================================================="
    echo "Configuring PulseAudio audio bridge and PRoot environment..."

    MISSING_PKGS=""
    command -v proot-distro >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS proot-distro"
    command -v pulseaudio >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS pulseaudio"
    command -v curl >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS curl"

    if [ -n "$MISSING_PKGS" ]; then
        echo "📦 Installing required Termux packages:$MISSING_PKGS..."
        pkg update -y -qq
        pkg install -y -qq $MISSING_PKGS
    fi

    # Start audio bridge to Android OpenSL ES
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true

    # Ensure Ubuntu PRoot is installed
    if ! proot-distro list 2>/dev/null | grep -A 2 "ubuntu" | grep -q "installed"; then
        echo "🐧 Installing Ubuntu Linux environment in PRoot (one-time setup)..."
        proot-distro install ubuntu
    fi

    # Create host wrapper shortcut so user can just type 'lisn' directly in Termux
    mkdir -p "$PREFIX/bin"
    cat << 'EOF' > "$PREFIX/bin/lisn"
#!/usr/bin/env bash
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true
proot-distro login ubuntu -- bash -c "export PULSE_SERVER=127.0.0.1; export TERM=xterm-256color; exec lisn \"\$@\"" -- "$@"
EOF
    chmod +x "$PREFIX/bin/lisn"

    # Forward execution into PRoot Ubuntu using this same script
    proot-distro login ubuntu -- bash -c '
        set -e
        if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v yt-dlp >/dev/null 2>&1 || ! command -v pulseaudio >/dev/null 2>&1; then
            echo "📦 Installing system dependencies in Ubuntu (ffmpeg, yt-dlp, pulseaudio)..."
            apt-get update -qq && apt-get install -y -qq ffmpeg yt-dlp pulseaudio curl ca-certificates tar
        fi
        export PULSE_SERVER=127.0.0.1
        export TERM=xterm-256color
        curl -sSL "https://raw.githubusercontent.com/shdynila/lisn-tui-releases/main/run.sh" | bash -s -- "$@"
    ' -- "$@"
    exit $?
fi

# 2. Universal Linux & macOS Runner
INSTALL_DIR="${HOME}/.lisn-tui/bin"
if [ "$(id -u)" -eq 0 ] && [ -d "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
fi

BIN_PATH="${INSTALL_DIR}/lisn"
VERSION_FILE="${HOME}/.lisn-tui/version.txt"
[ -d "${HOME}/.lisn-tui" ] || mkdir -p "${HOME}/.lisn-tui"

echo "🔍 Checking for latest LISN-TUI release..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)

if [ -z "$LATEST_TAG" ]; then
    if [ -x "$BIN_PATH" ]; then
        echo "⚠️ Offline: Launching local binary..."
        exec "$BIN_PATH" "$@"
    else
        echo "❌ Cannot connect to GitHub API and no installed binary was found."
        exit 1
    fi
fi

CURRENT_TAG=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_TAG=$(cat "$VERSION_FILE" 2>/dev/null || true)
fi

# Detect OS and CPU Architecture
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
        echo "For Windows, run: irm https://raw.githubusercontent.com/${REPO}/main/run.ps1 | iex"
        exit 1
        ;;
esac

# Launch if already on the latest version
if [ -x "$BIN_PATH" ] && [ "$CURRENT_TAG" = "$LATEST_TAG" ]; then
    exec "$BIN_PATH" "$@"
fi

echo "📥 Installing / Updating LISN-TUI (${LATEST_TAG}) for ${OS} (${ARCH})..."
mkdir -p "$INSTALL_DIR"

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
TMP_DIR=$(mktemp -d)
TMP_TAR="${TMP_DIR}/lisn.tar.gz"

curl -f -sSL -o "$TMP_TAR" "$DOWNLOAD_URL" || {
    echo "❌ Failed to download release asset from: $DOWNLOAD_URL"
    rm -rf "$TMP_DIR"
    exit 1
}

tar -xzf "$TMP_TAR" -C "$TMP_DIR"
mv "${TMP_DIR}/lisn" "$BIN_PATH"
chmod +x "$BIN_PATH"
echo "$LATEST_TAG" > "$VERSION_FILE"
rm -rf "$TMP_DIR"

# Add INSTALL_DIR to user PATH in ~/.bashrc if not already present
if [ "$INSTALL_DIR" != "/usr/local/bin" ] && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    if [ -f "$HOME/.bashrc" ] && ! grep -q "$INSTALL_DIR" "$HOME/.bashrc"; then
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
    fi
fi

echo "✅ LISN-TUI ${LATEST_TAG} ready in ${INSTALL_DIR}"
echo ""

exec "$BIN_PATH" "$@"
