#!/usr/bin/env bash
set -e

# ==============================================================================
# LISN-TUI Android Termux Automated Launcher & Installer
# Zero-config setup: PulseAudio audio bridge + Ubuntu PRoot + ARM64 Neural Engine
# ==============================================================================

REPO="shdynila/lisn-tui-releases"

echo "================================================================="
echo "🎧 LISN-TUI Android / Termux Auto-Installer & Launcher"
echo "================================================================="

# 1. Verify Termux environment
if [ -z "$TERMUX_VERSION" ] && [ ! -d "/data/data/com.termux" ]; then
    echo "⚠️ This script is intended to run inside Termux on Android."
    echo "If you are on desktop Linux, please run 'run.sh' instead."
    exit 1
fi

# 2. Ensure prerequisites in Termux host
echo "📦 Verifying Termux packages (proot-distro, pulseaudio, curl)..."
MISSING_PKGS=""
command -v proot-distro >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS proot-distro"
command -v pulseaudio >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS pulseaudio"
command -v curl >/dev/null 2>&1 || MISSING_PKGS="$MISSING_PKGS curl"

if [ -n "$MISSING_PKGS" ]; then
    echo "Installing missing packages:$MISSING_PKGS..."
    pkg update -y
    pkg install -y $MISSING_PKGS
fi

# 3. Start PulseAudio server in Termux (routes sound to Android OpenSL ES)
echo "🔊 Ensuring PulseAudio sound server is running..."
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true

# 4. Ensure Ubuntu container in proot-distro
if ! proot-distro list 2>/dev/null | grep -A 2 "ubuntu" | grep -q "installed"; then
    echo "🐧 Installing Ubuntu Linux environment in PRoot (one-time setup)..."
    proot-distro install ubuntu
fi

# 5. Create / update the host quick-launch command in Termux ($PREFIX/bin/lisn)
mkdir -p "$PREFIX/bin"
cat << 'EOF' > "$PREFIX/bin/lisn"
#!/usr/bin/env bash
# Start audio server if not active
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 2>/dev/null || true
# Launch inside proot
proot-distro login ubuntu -- bash -c "export PULSE_SERVER=127.0.0.1; export TERM=xterm-256color; exec lisn \"\$@\"" -- "$@"
EOF
chmod +x "$PREFIX/bin/lisn"

# 6. Run the internal setup and launch inside PRoot Ubuntu
echo "🚀 Bootstrapping LISN-TUI inside Ubuntu environment..."
proot-distro login ubuntu -- bash << 'UBUNTU_SCRIPT'
set -e

# Update packages if needed
if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v yt-dlp >/dev/null 2>&1 || ! command -v pulseaudio >/dev/null 2>&1; then
    echo "📦 Installing system dependencies in Ubuntu (ffmpeg, yt-dlp, pulseaudio)..."
    apt-get update -qq
    apt-get install -y -qq ffmpeg yt-dlp pulseaudio curl ca-certificates tar
fi

REPO="shdynila/lisn-tui-releases"
BIN_TARGET="/usr/local/bin/lisn"
VERSION_FILE="/var/lib/lisn_version.txt"

# Check latest release
LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)

CURRENT_TAG=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_TAG=$(cat "$VERSION_FILE" 2>/dev/null || true)
fi

if [ ! -x "$BIN_TARGET" ] || [ "$CURRENT_TAG" != "$LATEST_TAG" ]; then
    if [ -n "$LATEST_TAG" ]; then
        echo "📥 Downloading LISN-TUI ${LATEST_TAG} for Linux ARM64..."
        DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/lisn_linux_arm64.tar.gz"
        TMP_DIR=$(mktemp -d)
        curl -f -sSL -o "${TMP_DIR}/lisn.tar.gz" "$DOWNLOAD_URL"
        tar -xzf "${TMP_DIR}/lisn.tar.gz" -C "$TMP_DIR"
        mv "${TMP_DIR}/lisn" "$BIN_TARGET"
        chmod +x "$BIN_TARGET"
        echo "$LATEST_TAG" > "$VERSION_FILE"
        rm -rf "$TMP_DIR"
        echo "✅ Installed LISN-TUI ${LATEST_TAG} to ${BIN_TARGET}"
    else
        if [ ! -x "$BIN_TARGET" ]; then
            echo "❌ Failed to fetch latest release from GitHub."
            exit 1
        fi
    fi
fi

# Ensure audio environment
export PULSE_SERVER=127.0.0.1
export TERM=xterm-256color

echo "🎶 Launching LISN-TUI..."
exec "$BIN_TARGET"
UBUNTU_SCRIPT

echo ""
echo "🎉 Session ended. Next time in Termux, simply type:"
echo "    lisn"
echo "to launch immediately!"
