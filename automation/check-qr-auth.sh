#!/bin/bash

# ===============================
# WhatsApp MCP QR Authentication Helper
# ===============================
# This script checks if WhatsApp needs re-authentication via QR code scan,
# and if so, it automatically opens a Terminal window with the QR code
# and sends a notification to the user.
#
# WhatsApp web sessions typically expire after about 20 days, and this
# script helps automate the re-authentication process.
#
# This script is run:
# - At system startup
# - Once per day via LaunchAgent
#
# Author: Gopal Shivapuja
# ===============================

# --- Path variables ---
# LOG_FILE: Where the WhatsApp bridge logs its output
# QR_NEEDED_FILE: A marker file to prevent opening multiple QR windows
# BRIDGE_DIR: Directory containing the WhatsApp bridge code
LOG_FILE="$HOME/Library/Logs/whatsapp-mcp.log"
QR_NEEDED_FILE="$(dirname "$0")/../.qr_needed"
BRIDGE_DIR="$(dirname "$0")/../whatsapp-bridge"

# --- Ensure log directory and file exist ---
# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
# Create empty log file if it doesn't exist
touch "$LOG_FILE"

# --- Check if re-authentication is needed ---
# Search for "scan QR code" message in the logs
if grep -q "scan QR code" "$LOG_FILE"; then
    # Find the line number of the most recent QR code request
    LAST_AUTH_REQUEST=$(grep -n "scan QR code" "$LOG_FILE" | tail -1 | cut -d: -f1)
    
    # If we found a QR code request line...
    if [ ! -z "$LAST_AUTH_REQUEST" ]; then
        # Get the total number of lines in the log file
        LOG_LINES=$(wc -l < "$LOG_FILE")
        
        # --- Check if the QR code was already scanned ---
        # Look for successful connection message after the QR request
        if ! tail -n $(( LOG_LINES - LAST_AUTH_REQUEST )) "$LOG_FILE" | grep -q "Connected to WhatsApp"; then
            # No successful connection found - QR code still needs to be scanned
            
            # --- Show QR code to user (if not already shown) ---
            # Check if marker file exists to prevent multiple QR windows
            if [ ! -f "$QR_NEEDED_FILE" ]; then
                # Create marker file to indicate we're showing QR code
                touch "$QR_NEEDED_FILE"
                
                # --- Launch Terminal with WhatsApp bridge showing QR code ---
                # Uses AppleScript to create a customized Terminal experience
                osascript -e 'tell app "Terminal"
                    do script "cd "'$BRIDGE_DIR'" && clear && echo \"WhatsApp re-authentication required. Please scan this QR code with your phone:\" && echo \"\" && go run main.go"
                    set the custom title of the front window to "WhatsApp QR Code Authentication"
                    set position of the front window to {100, 100}
                    set size of the front window to {800, 600}
                    activate
                end tell'
                
                # --- Send user notification ---
                # Uses macOS notification system to alert the user
                osascript -e 'display notification "Please scan the QR code in the terminal window to reconnect your WhatsApp account." with title "WhatsApp Authentication Required" sound name "Ping"'
            fi
        else
            # --- QR code has been successfully scanned ---
            # Clean up: remove the marker file if it exists
            if [ -f "$QR_NEEDED_FILE" ]; then
                rm "$QR_NEEDED_FILE"
            fi
        fi
    fi
fi