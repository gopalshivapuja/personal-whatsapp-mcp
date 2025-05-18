#!/bin/bash

# ===============================
# WhatsApp MCP Automation Uninstaller
# ===============================
# This script safely removes all automation components for WhatsApp MCP
# while preserving your WhatsApp data and messages.
#
# It will:
# 1. Unload all LaunchAgents from launchctl (stop background services)
# 2. Remove LaunchAgent plist files from the user's Library
# 
# Author: Gopal Shivapuja
# ===============================

echo "Uninstalling WhatsApp MCP automation..."

# Path to user's LaunchAgents directory (macOS standard location)
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"

# --- Stop all running services ---
# Unload launch agents using launchctl (macOS service manager)
# The '2>/dev/null || true' ensures script continues even if a service wasn't loaded
launchctl unload "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-watchdog.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-qrauth.plist" 2>/dev/null || true

# --- Clean up LaunchAgent files ---
# Remove the plist files from the LaunchAgents directory
# The -f flag ensures no error if files don't exist
rm -f "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp.plist"
rm -f "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-watchdog.plist"
rm -f "$LAUNCH_AGENT_DIR/com.user.whatsapp-mcp-qrauth.plist"

# --- Success message and next steps ---
echo "WhatsApp MCP automation has been uninstalled."
echo "Note: This script only removes the automation setup. Your WhatsApp data is still preserved."
echo "To completely remove WhatsApp MCP, delete the repository directory."