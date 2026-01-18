#!/bin/bash

# REDRIVER2 Launcher & Setup Script
# Handles resource extraction and FMV conversion on first run

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESOURCES_DIR="$DIR/../Resources"
DATA_DIR="$RESOURCES_DIR/data"
GAME_DIR="$DATA_DIR/DRIVER2"
INSTALL_TOOLS_DIR="$DATA_DIR/install"
BINARY="$DIR/REDRIVER2"
SETUP_UI="$DIR/REDRIVER2_Setup"

# Helper for dialogs (Fallback if UI fails)
function show_alert() {
    osascript -e "display dialog \"$1\" buttons {\"OK\"} default button \"OK\" with icon note with title \"REDRIVER2 Setup v1.1\""
}

# --- Main Launcher Logic ---

# Always run the Swift Launcher UI
# It will handle:
# 1. Installation (if needed)
# 2. Options (Re-extract, FMV)
# 3. Launching the game (returns "LAUNCH" to stdout)

if [ -f "$SETUP_UI" ]; then
    # Run Setup UI and capture output
    OUTPUT=$("$SETUP_UI")
    
    # Check if user clicked "Play"
    if echo "$OUTPUT" | grep -q "LAUNCH"; then
        echo "Launching REDRIVER2..."
        
        # Change CWD to Resources so the game can find 'data' folder
        cd "$RESOURCES_DIR"
        exec "$BINARY"
    else
        # User quit or cancelled
        exit 0
    fi
else
    show_alert "Launcher UI not found! Please reinstall the application."
    exit 1
fi
