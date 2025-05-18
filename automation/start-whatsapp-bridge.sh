#!/bin/bash

# ===============================
# WhatsApp MCP Bridge Starter
# ===============================
# This script manually starts the WhatsApp bridge if it's not already running.
# It's useful for:
# - Initial setup
# - Manual restart if needed
# - Testing purposes
#
# If the bridge is already running, it simply informs the user.
#
# Author: Gopal Shivapuja
# ===============================

# --- Change to the WhatsApp bridge directory ---
# Use the script's location to find the bridge directory
cd "$(dirname "$0")/../whatsapp-bridge"

# --- Check if bridge is already running ---
# pgrep looks for the process pattern "go run main.go"
if pgrep -f "go run main.go" > /dev/null; then
    # Bridge is already running, inform the user
    echo "WhatsApp bridge is already running."
else
    # Bridge is not running, start it
    echo "Starting WhatsApp bridge..."
    
    # --- Start the bridge ---
    # Run the Go application in the background (with &)
    go run main.go &
    
    # --- Confirm successful start ---
    # $! contains the PID of the most recently started background process
    echo "WhatsApp bridge started with PID $!"
fi