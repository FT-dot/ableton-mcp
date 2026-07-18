#!/bin/bash
# Restart Ableton Live — used after installing new Remote Script
# Usage: ./scripts/restart_ableton.sh [--no-save]
#
# On Windows (Git Bash/MSYS) this delegates to restart_ableton.ps1.

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        PS1_PATH="$(dirname "$0")/restart_ableton.ps1"
        exec powershell.exe -NoProfile -ExecutionPolicy Bypass \
            -File "$(cygpath -w "$PS1_PATH" 2>/dev/null || echo "$PS1_PATH")" "$@"
        ;;
esac

ABLETON_APP="Ableton Live 12 Suite"

# Check if Ableton is running
if ! pgrep -x "Live" > /dev/null 2>&1; then
    echo "Ableton is not running. Starting it..."
    open -a "$ABLETON_APP"
    echo "Ableton started."
    exit 0
fi

# Quit Ableton gracefully (will trigger save dialog)
echo "Quitting Ableton..."
osascript -e "tell application \"$ABLETON_APP\" to quit"

# Wait for it to close (max 30 seconds)
for i in $(seq 1 30); do
    if ! pgrep -x "Live" > /dev/null 2>&1; then
        echo "Ableton closed."
        break
    fi
    sleep 1
done

# If still running after 30s, force kill
if pgrep -x "Live" > /dev/null 2>&1; then
    echo "Ableton didn't close gracefully. Force quitting..."
    pkill -x "Live"
    sleep 2
fi

# Relaunch
echo "Starting Ableton..."
sleep 1
open -a "$ABLETON_APP"
echo "Ableton restarted."
