# LISN-TUI Releases & Distribution Hub

Official public distribution hub and automated release portal for **[LISN-TUI](https://github.com/shdynila/lisn-tui)** — the offline, neural-powered music stem separation workstation and multi-track audio player for the terminal.

🌐 **Website & Download Portal:** [https://shdynila.github.io/lisn-tui-releases/](https://shdynila.github.io/lisn-tui-releases/)

---

## ⚡ Instant One-Liner Installers

No compiling, no Git cloning, no manual tool installations required.

### 📱 Android Phone (Termux)
Run this single command inside Termux to set up the PulseAudio sound bridge, Linux ARM64 neural environment, and launch LISN-TUI:
```bash
curl -sSL https://raw.githubusercontent.com/shdynila/lisn-tui-releases/main/termux.sh | bash
```
*(On subsequent runs, simply type `lisn` in Termux!)*

### 🐧 Linux (x86_64 & ARM64)
```bash
curl -sSL https://raw.githubusercontent.com/shdynila/lisn-tui-releases/main/run.sh | bash
```

### 🍎 macOS (Apple Silicon & Intel)
```bash
curl -sSL https://raw.githubusercontent.com/shdynila/lisn-tui-releases/main/run.sh | bash
```

### 🪟 Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/shdynila/lisn-tui-releases/main/run.ps1 | iex
```

---

## 📦 Direct Downloads

Check the [Releases](../../releases) tab for pre-compiled standalone archives:

| Platform | Architecture | Binary Package | Notes |
| :--- | :--- | :--- | :--- |
| **Android (Termux)** | ARM64 (`aarch64`) | `lisn_linux_arm64.tar.gz` | Runs in PRoot Ubuntu with PulseAudio TCP |
| **Linux** | x86_64 (`amd64`) | `lisn_linux_amd64.tar.gz` | AVX2 / FMA CPU accelerated |
| **Linux** | ARM64 (`aarch64`) | `lisn_linux_arm64.tar.gz` | ARM NEON CPU accelerated |
| **macOS** | Apple Silicon (`arm64`) | `lisn_mac_silicon.tar.gz` | M1 / M2 / M3 / M4 native |
| **macOS** | Intel (`x86_64`) | `lisn_mac_intel.tar.gz` | macOS 11+ |
| **Windows** | x86_64 (`amd64`) | `lisn_windows_amd64.zip` | Windows 10 & 11 |

---

## 🛠️ Automated First-Run Setup

Every build of LISN-TUI includes automated engine bootstrapping:
1. **Neural Runtime**: Automatically downloads and uncompresses the official Microsoft ONNX Runtime shared library (`onnxruntime.dll`, `libonnxruntime.so`, or `libonnxruntime.dylib`) directly for your CPU architecture.
2. **Model Weights**: Automatically downloads pre-trained MDX-Net 44.1kHz STFT neural weights on demand with real-time progress bars.
3. **Audio Routing**: Automatically configures audio output to default system audio devices (or PulseAudio TCP on Android).

---

## 🐛 Bug Reports & Feedback

Found a bug, playback glitch, or installation issue with the pre-compiled binaries?  
Open an issue in our public [Issues](../../issues) tracker!
