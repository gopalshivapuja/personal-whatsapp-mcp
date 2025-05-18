#!/bin/bash

# ===============================
# WhatsApp MCP Automation Setup
# ===============================
# This script sets up all automation for the WhatsApp MCP system on macOS.
# It checks dependencies, installs Python requirements, creates LaunchAgents,
# and ensures the bridge and automation scripts run at startup and daily.
#
# Author: Gopal Shivapuja (enhancements)
# Original: Luke Harries (core MCP)
# ===============================

echo "Setting up WhatsApp MCP automation..."

# --- Directory variables ---
# SCRIPT_DIR: Directory where this script is located
# REPO_DIR:   Root of the repository
# LAUNCH_AGENT_DIR: Where macOS user LaunchAgents are stored
# LOG_DIR:    Where logs will be written
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs"

# --- Create necessary directories ---
mkdir -p "$LAUNCH_AGENT_DIR"
mkdir -p "$LOG_DIR"

# --- Make all automation scripts executable ---
chmod +x "$SCRIPT_DIR/start-whatsapp-bridge.sh"
chmod +x "$SCRIPT_DIR/check-and-restart-bridge.sh"
chmod +x "$SCRIPT_DIR/check-qr-auth.sh"

# --- Dependency checks ---
# Check for Go (required for the bridge)
command -v go >/dev/null 2>&1 || { echo >&2 "Go is not installed. Please install Go and try again."; exit 1; }
# Check for Python 3 (required for the MCP server)
command -v python3 >/dev/null 2>&1 || { echo >&2 "Python 3 is not installed. Please install Python 3 and try again."; exit 1; }

# Check for Python dependency managers and install requirements if needed
if ! command -v uv >/dev/null 2>&1; then
  echo "UV is not installed. Attempting to install Python requirements with pip..."
  if command -v pip3 >/dev/null 2>&1; then
    pip3 install -r "$REPO_DIR/whatsapp-mcp-server/requirements.txt" || { echo >&2 "Failed to install Python requirements with pip3."; exit 1; }
  elif command -v pip >/dev/null 2>&1; then
    pip install -r "$REPO_DIR/whatsapp-mcp-server/requirements.txt" || { echo >&2 "Failed to install Python requirements with pip."; exit 1; }
  else
    echo >&2 "Neither uv nor pip is installed. Please install one of them to proceed."; exit 1;
  fi
else
  echo "UV is installed. Please use 'uv pip install -r whatsapp-mcp-server/requirements.txt' if you need to manually install dependencies."
fi

# Check for FFmpeg (optional, for voice message conversion)
command -v ffmpeg >/dev/null 2>&1 || echo "Warning: FFmpeg is not installed. Voice message conversion will not work."
# Check for osascript (required for macOS notifications and Terminal automation)
command -v osascript >/dev/null 2>&1 || { echo >&2 "osascript is required (macOS only). This script is designed for macOS."; exit 1; }

# --- Create LaunchAgents for automation ---
# 1. Main WhatsApp bridge service (runs at login and stays alive)
cat > "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp.plist" << EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.whatsapp-mcp</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd $REPO_DIR/whatsapp-bridge && go run main.go</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/whatsapp-mcp.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/whatsapp-mcp-error.log</string>
</dict>
</plist>
EOT

# 2. Watchdog service (checks once per day if the bridge is running)
cat > "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-watchdog.plist" << EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.whatsapp-mcp-watchdog</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_DIR/check-and-restart-bridge.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>86400</integer> <!-- 86400 seconds = 1 day -->
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOT

# 3. QR authentication helper (shows QR code if re-auth is needed)
cat > "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-qrauth.plist" << EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.whatsapp-mcp-qrauth</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_DIR/check-qr-auth.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>86400</integer> <!-- 86400 seconds = 1 day -->
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOT

# --- Load (activate) the LaunchAgents ---
# Unload first to avoid duplicates or stale configs
launchctl unload "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-watchdog.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-qrauth.plist" 2>/dev/null || true

# Load the new/updated agents
launchctl load "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp.plist"
launchctl load "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-watchdog.plist"
launchctl load "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-qrauth.plist"

# --- Final user messages ---
echo "WhatsApp MCP automation setup complete!"
echo "The WhatsApp bridge should start automatically."
echo "If you need to scan a QR code, a terminal window will open automatically."
echo "Logs are stored in $LOG_DIR/"
echo ""
echo "If you prefer pip, you can install Python dependencies with:"
echo "  pip install -r whatsapp-mcp-server/requirements.txt"