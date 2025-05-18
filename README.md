# Enhanced WhatsApp MCP Server

This repository contains an enhanced version of the [WhatsApp MCP Server](https://github.com/lharries/whatsapp-mcp) by Luke Harries, with added automation scripts for easy setup, automatic startup, self-monitoring, and automatic QR code authentication.

> **Credit**: This project is based on the excellent [WhatsApp MCP Server](https://github.com/lharries/whatsapp-mcp) by [Luke Harries](https://github.com/lharries). I've added automation scripts to enhance usability while maintaining the core functionality of the original project.

## What This Does

This WhatsApp MCP Server allows you to:
- Connect your WhatsApp account to AI assistants like Claude
- Search and read your WhatsApp messages from your AI assistant
- Send messages and media through WhatsApp via your AI assistant
- Automatically handle keeping the service running

## Enhanced Features

This version adds several improvements to the original project:
- **Automatic Startup**: The WhatsApp bridge starts automatically when your system boots
- **Daily Self-Check**: The system checks once per day if the service is running and restarts it if needed
- **QR Code Authentication**: When your session expires (typically after 20+ days), the system automatically shows a QR code for re-authentication
- **System Notifications**: You get notified when action is required
- **Comprehensive Logging**: All activities are properly logged for easy troubleshooting

## Installation

### Prerequisites

- macOS (the automation scripts are designed for macOS)
- Go
- Python 3.6+
- UV (Python package manager), install with `curl -LsSf https://astral.sh/uv/install.sh | sh`
- FFmpeg (optional) - Only needed for sending voice messages

### Step-by-Step Installation

1. **Clone this repository**
   ```bash
   git clone https://github.com/gopalshivapuja/personal-whatsapp-mcp.git
   cd personal-whatsapp-mcp
   ```

2. **Run the WhatsApp bridge for initial setup**
   ```bash
   cd whatsapp-bridge
   go run main.go
   ```
   Scan the QR code with your WhatsApp mobile app to authenticate.

3. **Run the automation setup script**
   ```bash
   cd ..
   bash automation/setup.sh
   ```
   This will:
   - Create launch agents to run the service at system startup
   - Set up a daily watchdog to check if the service is running
   - Configure automatic QR code display when re-authentication is needed
   - Start the WhatsApp bridge immediately

4. **Connect to Claude or another AI assistant**

   Copy this JSON configuration, replacing the paths as needed:
   ```json
   {
     "mcpServers": {
       "whatsapp": {
         "command": "/path/to/uv", // Run `which uv` to find this
         "args": [
           "--directory",
           "/path/to/personal-whatsapp-mcp/whatsapp-mcp-server", // Use full path
           "run",
           "main.py"
         ]
       }
     }
   }
   ```
   
   For Claude Desktop, save this as:
   `~/Library/Application Support/Claude/claude_desktop_config.json`
   
   For Cursor, save this as:
   `~/.cursor/mcp.json`

## How the Automation Works

### Automatic Startup
The WhatsApp bridge is configured to start automatically when your system boots through a macOS Launch Agent.

### Watchdog Service
Once per day and at system startup, a watchdog script checks if the WhatsApp bridge is running. If it's not, the watchdog automatically restarts it and logs the action.

### QR Authentication Helper
When your WhatsApp session expires (typically after 20+ days), the system:
- Detects that re-authentication is needed
- Opens a terminal window showing the QR code
- Displays a system notification
- Automatically resumes normal operation after you scan the code

### Logging System
All operations are logged to:
- WhatsApp bridge: `~/Library/Logs/whatsapp-mcp.log`
- Error log: `~/Library/Logs/whatsapp-mcp-error.log`
- Watchdog log: `~/Library/Logs/whatsapp-mcp-watchdog.log`

## Managing the Service

### Checking Status
To confirm the service is running:
```bash
launchctl list | grep whatsapp
```

### Viewing Logs
```bash
tail -f ~/Library/Logs/whatsapp-mcp.log
```

### Manual Start
If you need to manually start the bridge:
```bash
bash automation/start-whatsapp-bridge.sh
```

### Uninstalling
To remove the automation but keep your data:
```bash
bash automation/uninstall.sh
```

## Troubleshooting

### QR Code Not Appearing
If you need to force a QR code to appear:
```bash
cd whatsapp-bridge
go run main.go
```

### Bridge Not Starting
Check the logs for error messages:
```bash
cat ~/Library/Logs/whatsapp-mcp-error.log
```

### Authentication Issues
If you're having trouble with authentication:
- Delete the database files: `rm whatsapp-bridge/store/*.db`
- Restart the bridge: `cd whatsapp-bridge && go run main.go`
- Scan the QR code with your phone

## Migrating to a New Computer
To set up this system on a new computer:
1. Install the prerequisites (Go, Python, UV)
2. Clone this repository
3. Run the setup script: `bash automation/setup.sh`
4. Authenticate with WhatsApp when prompted
5. Configure Claude or your AI assistant as described above

## Technical Details

### Automation Components
The system consists of three main components:

1. **Primary WhatsApp Bridge Service**
   - Starts the WhatsApp connection
   - Handles message syncing
   - Provides the MCP server interface

2. **Watchdog Service**
   - Runs once daily and at system boot
   - Checks if the bridge is running
   - Automatically restarts it if needed

3. **QR Authentication Helper**
   - Runs once daily and at system boot
   - Monitors logs for authentication requests
   - Displays QR code when needed

### File Locations
- Launch Agents: `~/Library/LaunchAgents/com.user.whatsapp-mcp*.plist`
- Log Files: `~/Library/Logs/whatsapp-mcp*.log`
- Database: `whatsapp-bridge/store/*.db`
- Scripts: `automation/*.sh`

## Credits and Acknowledgements

- **Original WhatsApp MCP Server**: Created by Luke Harries. Please visit the original repository for more information about the core functionality.
- **WhatsApp Connection**: Based on the whatsmeow library by Tulir Asokan.
- **Automation Scripts**: Added by Gopal Shivapuja to enhance the user experience.

This project is provided as-is without warranty. Please use responsibly and in accordance with WhatsApp's terms of service.
