#!/bin/bash

echo "🔒 Configuring environment for secure online test..."

# Wait for VS Code to be ready
sleep 3

# Close any open Copilot chat panels
echo "  Closing Copilot chat if open..."
code --command workbench.action.closeAuxiliaryBar 2>/dev/null || true
code --command workbench.action.chat.close 2>/dev/null || true
code --command workbench.action.closePanel 2>/dev/null || true

# Create VS Code settings to disable Copilot and hide UI elements
echo "  Creating VS Code settings..."
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  // DISABLE all Copilot functionality
  "github.copilot.enable": false,
  "github.copilot.advanced": {
    "disabled": true,
    "debug.enabled": false
  },
  "github.copilot.chat.enabled": false,
  "github.copilot.voice.enabled": false,
  "github.copilot.editor.enableAutoCompletions": false,
  "github.copilot.editor.enableCodeActions": false,

  // Hide all Copilot UI elements
  "workbench.auxiliaryBar.enabled": false,
  "workbench.auxiliaryBar.visible": false,
  "workbench.panel.chat.hidden": true,
  "chat.commandCenter.enabled": false,

  // Hide the entire status bar
  "workbench.statusBar.visible": false,

  // Hide Extensions to prevent re-enabling
  "workbench.activityBar.visible": true,
  "workbench.view.extensions.visible": false,

  // Disable all suggestions and IntelliSense
  "editor.quickSuggestions": {
    "other": false,
    "comments": false,
    "strings": false
  },
  "editor.suggestOnTriggerCharacters": false,
  "editor.acceptSuggestionOnCommitCharacter": false,
  "editor.acceptSuggestionOnEnter": "off",
  "editor.suggest.enabled": false,
  "editor.parameterHints.enabled": false,
  "editor.hover.enabled": false,

  // Disable inline completions and ghost text (removes "Start chat..." overlay)
  "editor.inlineSuggest.enabled": false,
  "editor.suggest.showInlineDetails": false,
  "editor.suggest.preview": false,
  "github.copilot.editor.enableCodeActions": false,
  "github.copilot.inlineSuggest.enable": false,

  // Disable welcome/getting started overlays
  "workbench.tips.enabled": false,
  "workbench.welcomePage.walkthroughs.openOnInstall": false,
  "editor.unicodeHighlight.nonBasicASCII": false,

  // Disable extensions auto-update to prevent changes
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "extensions.ignoreRecommendations": true
}
EOF

# Create keybindings to disable all Copilot and extension shortcuts
echo "  Disabling keybindings..."
cat > .vscode/keybindings.json << 'EOF'
[
  {
    "key": "ctrl+shift+x",
    "command": "-workbench.view.extensions"
  },
  {
    "key": "cmd+shift+x",
    "command": "-workbench.view.extensions"
  },
  {
    "key": "ctrl+i",
    "command": "-github.copilot.chat.open"
  },
  {
    "key": "cmd+i",
    "command": "-github.copilot.chat.open"
  },
  {
    "key": "ctrl+enter",
    "command": "-github.copilot.generate"
  },
  {
    "key": "cmd+enter",
    "command": "-github.copilot.generate"
  },
  {
    "key": "alt+\\",
    "command": "-github.copilot.toggleCopilot"
  },
  {
    "key": "alt+]",
    "command": "-github.copilot.nextSuggestion"
  },
  {
    "key": "alt+[",
    "command": "-github.copilot.previousSuggestion"
  },
  {
    "key": "tab",
    "command": "-github.copilot.acceptSuggestion",
    "when": "github.copilot.inProgress"
  },
  {
    "key": "ctrl+shift+p",
    "command": "-workbench.action.showCommands"
  },
  {
    "key": "cmd+shift+p",
    "command": "-workbench.action.showCommands"
  },
  {
    "key": "f1",
    "command": "-workbench.action.showCommands"
  }
]
EOF

# Force uninstall Copilot if it exists
echo "  Checking for Copilot extensions..."
code --uninstall-extension GitHub.copilot --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-nightly --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-labs --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-chat --force 2>/dev/null || true

# Create and launch the monitoring daemon
echo "  Setting up Copilot monitoring daemon..."

# Create the monitor script
cat > "$HOME/.monitor_copilot.sh" << 'MONITOR_SCRIPT'
#!/bin/bash

# Copilot Monitoring Daemon for Online Tests
LOG_FILE="$HOME/copilot_violations.log"
CHECK_INTERVAL=5  # Check every 5 seconds
VIOLATION_COUNT=0

# Initialize log file
echo "=== Copilot Monitor Started at $(date) ===" > "$LOG_FILE"
echo "Monitoring for unauthorized Copilot usage during test" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Function to check for Copilot extensions
check_copilot() {
    local copilot_found=false
    local extensions=$(code --list-extensions 2>/dev/null || echo "")

    for ext in $extensions; do
        if [[ "$ext" =~ [Cc]opilot ]]; then
            copilot_found=true
            VIOLATION_COUNT=$((VIOLATION_COUNT + 1))

            # Log the violation
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] VIOLATION #$VIOLATION_COUNT: Copilot extension detected: $ext" | tee -a "$LOG_FILE"
            echo "  User: $(whoami)" >> "$LOG_FILE"
            echo "  Workspace: $(pwd)" >> "$LOG_FILE"

            # Attempt to uninstall
            echo "  Attempting to remove $ext..." | tee -a "$LOG_FILE"
            code --uninstall-extension "$ext" --force 2>&1 >> "$LOG_FILE"

            # Create violation marker
            echo "COPILOT VIOLATION DETECTED at $(date)" > "$HOME/VIOLATION_DETECTED.txt"

            echo "" >> "$LOG_FILE"
        fi
    done

    return $([ "$copilot_found" = true ] && echo 1 || echo 0)
}

# Main monitoring loop
while true; do
    check_copilot
    sleep $CHECK_INTERVAL
done
MONITOR_SCRIPT

chmod +x "$HOME/.monitor_copilot.sh"

# Kill any existing monitor processes
pkill -f "monitor_copilot.sh" 2>/dev/null || true

# Launch the daemon
nohup "$HOME/.monitor_copilot.sh" > "$HOME/.monitor_output.log" 2>&1 &
MONITOR_PID=$!

# Verify daemon is running
sleep 1
if ps -p $MONITOR_PID > /dev/null; then
    echo "  ✓ Monitor daemon started successfully (PID: $MONITOR_PID)"
else
    echo "  ⚠️  Warning: Monitor daemon may not have started properly"
fi

# Create a stop script for after the test
cat > "$HOME/stop_monitor.sh" << EOF
#!/bin/bash
echo "Stopping Copilot monitor..."
kill $MONITOR_PID 2>/dev/null || true
pkill -f "monitor_copilot.sh" 2>/dev/null || true
echo "Monitor stopped."
echo "Check violations log at: ~/copilot_violations.log"
EOF
chmod +x "$HOME/stop_monitor.sh"

echo "✅ Test environment configured!"
echo ""
echo "🔒 ONLINE TEST MODE ACTIVE:"
echo "   ✓ Copilot completely disabled"
echo "   ✓ All AI assistance blocked"
echo "   ✓ Extensions panel hidden"
echo "   ✓ Command palette disabled (F1, Ctrl/Cmd+Shift+P)"
echo "   ✓ IntelliSense and suggestions disabled"
echo "   ✓ Inline hints and ghost text removed"
echo "   ✓ Copilot chat closed"
echo "   ✓ Monitoring active (PID: $MONITOR_PID)"
echo ""
echo "⚠️  Any attempts to enable Copilot will be logged to ~/copilot_violations.log"
echo "🛑 To stop monitoring after test: run ~/stop_monitor.sh"
echo ""
echo "📝 Students must write all code independently for this test."

# Show initial status
echo ""
echo "Current status:"
echo "  Extensions installed: $(code --list-extensions 2>/dev/null | wc -l)"
echo "  Copilot extensions: $(code --list-extensions 2>/dev/null | grep -i copilot | wc -l)"
echo "  Monitor daemon: Running (PID: $MONITOR_PID)"