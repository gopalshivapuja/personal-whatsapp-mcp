#!/bin/bash

# ===============================
# WhatsApp MCP Watchdog Service
# ===============================
# This script monitors the WhatsApp bridge and restarts it if it's not running.
# It acts as a failsafe to ensure continuous operation of the WhatsApp connection.
#
# It is executed:
# - At system startup
# - Once per day via LaunchAgent
#
# All activities are logged for troubleshooting purposes.
#
# Author: Gopal Shivapuja
# ===============================

# --- Path variables ---
# BRIDGE_DIR: Location of the WhatsApp bridge code
# LOG_DIR: Directory where all logs are stored
BRIDGE_DIR="$(dirname "$0")/../whatsapp-bridge"
LOG_DIR="$HOME/Library/Logs"

# --- Ensure log directory exists ---
mkdir -p "$LOG_DIR"

# --- Check if WhatsApp bridge is running ---
# pgrep searches for processes matching the pattern "go run main.go"
# The '!' inverts the condition to check if it's NOT running
if ! pgrep -f "go run main.go" > /dev/null; then
    # --- Bridge not found, log and restart ---
    # Log with timestamp that the bridge needs to be restarted
    echo "$(date): WhatsApp bridge is not running. Restarting..." >> "$LOG_DIR/whatsapp-mcp-watchdog.log"
    
    # --- Restart the bridge ---
    # Change to the bridge directory and start the Go app in the background
    # Standard output goes to whatsapp-mcp.log
    # Error output goes to whatsapp-mcp-error.log
    # The '&' runs it as a background process
    cd "$BRIDGE_DIR" && go run main.go >> "$LOG_DIR/whatsapp-mcp.log" 2>> "$LOG_DIR/whatsapp-mcp-error.log" &
    
    # --- Log successful restart ---
    # $! contains the PID of the most recently started background process
    echo "$(date): WhatsApp bridge restarted with PID $!" >> "$LOG_DIR/whatsapp-mcp-watchdog.log"
else
    # --- Bridge is running normally ---
    # Simply log that everything is OK
    echo "$(date): WhatsApp bridge is running." >> "$LOG_DIR/whatsapp-mcp-watchdog.log"
fi