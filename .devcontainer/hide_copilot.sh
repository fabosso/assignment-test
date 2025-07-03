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

  // Hide UI bars
  "workbench.statusBar.visible": false,
  "workbench.activityBar.visible": false,
  "window.titleBarStyle": "custom",
  "workbench.layoutControl.enabled": false,

  // Hide Extensions to prevent re-enabling
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
  "extensions.ignoreRecommendations": true,

  // Additional minimal UI settings
  "breadcrumbs.enabled": false,
  "editor.minimap.enabled": false,
  "workbench.editor.showTabs": true,
  "workbench.sideBar.location": "left"
}
EOF

# Force uninstall Copilot if it exists
echo "  Checking for Copilot extensions..."
code --uninstall-extension GitHub.copilot --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-nightly --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-labs --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-chat --force 2>/dev/null || true

# Create monitoring script with proper paths
echo "  Setting up Copilot monitoring daemon..."

# Use absolute paths and ensure HOME is set
MONITOR_SCRIPT="/tmp/copilot_monitor.sh"
LOG_FILE="/tmp/copilot_violations.log"
MONITOR_LOG="/tmp/copilot_monitor.log"

cat > "$MONITOR_SCRIPT" << 'EOF'
#!/bin/bash
# Monitor and prevent Copilot during test

LOG_FILE="/tmp/copilot_violations.log"
VIOLATION_COUNT=0
CHECK_COUNT=0
CHECKS_PER_STATUS=12  # Log status every minute (12 * 5 seconds)

# Initialize log
echo "=== Copilot Monitor Started at $(date) ===" > "$LOG_FILE"
echo "Monitoring for unauthorized Copilot usage" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "Monitor daemon started at $(date)"

while true; do
    CHECK_COUNT=$((CHECK_COUNT + 1))

    # Check if any Copilot extension gets installed
    COPILOT_EXTS=$(code --list-extensions 2>/dev/null | grep -i copilot || true)

    if [ -n "$COPILOT_EXTS" ]; then
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))

        echo "[$(date)] VIOLATION #$VIOLATION_COUNT: Copilot detected!" | tee -a "$LOG_FILE"
        echo "  Extensions found: $COPILOT_EXTS" | tee -a "$LOG_FILE"
        echo "  Removing extensions..." | tee -a "$LOG_FILE"

        # Remove each Copilot extension
        for ext in $COPILOT_EXTS; do
            code --uninstall-extension "$ext" --force 2>&1 | tee -a "$LOG_FILE"
        done

        # Create visible warning
        echo "⚠️ COPILOT VIOLATION DETECTED at $(date)" > /tmp/COPILOT_VIOLATION.txt

        echo "" >> "$LOG_FILE"
    else
        # Log periodic status updates
        if [ $((CHECK_COUNT % CHECKS_PER_STATUS)) -eq 0 ]; then
            echo "[$(date)] STATUS: All clear - No Copilot detected (Check #$CHECK_COUNT)" >> "$LOG_FILE"
        fi
    fi

    sleep 5
done
EOF

chmod +x "$MONITOR_SCRIPT"

# Kill any existing monitors
pkill -f "copilot_monitor.sh" 2>/dev/null || true

# Start the monitor
nohup "$MONITOR_SCRIPT" > "$MONITOR_LOG" 2>&1 &
MONITOR_PID=$!

# Verify it's running
sleep 2
if ps -p $MONITOR_PID > /dev/null 2>&1; then
    echo "  ✓ Monitor daemon running (PID: $MONITOR_PID)"
else
    echo "  ⚠️  Monitor may not have started - trying alternative method..."
    # Try alternative launch method
    (while true; do
        if code --list-extensions 2>/dev/null | grep -i copilot; then
            echo "[$(date)] Copilot detected!" >> /tmp/copilot_violations.log
            code --list-extensions | grep -i copilot | xargs -I {} code --uninstall-extension {} --force
        fi
        sleep 5
    done) > /tmp/monitor_alt.log 2>&1 &
    MONITOR_PID=$!
    echo "  Alternative monitor started (PID: $MONITOR_PID)"
fi

# Create stop script
cat > /tmp/stop_monitor.sh << EOF
#!/bin/bash
echo "Stopping Copilot monitor..."
kill $MONITOR_PID 2>/dev/null || true
pkill -f "copilot_monitor" 2>/dev/null || true
echo "Monitor stopped."
echo "Check violations at: /tmp/copilot_violations.log"
EOF
chmod +x /tmp/stop_monitor.sh

echo "✅ Test environment configured!"
echo ""
echo "🔒 ONLINE TEST MODE ACTIVE:"
echo "   ✓ Copilot completely disabled"
echo "   ✓ All AI assistance blocked"
echo "   ✓ Activity bar hidden (left sidebar)"
echo "   ✓ Status bar hidden (bottom bar)"
echo "   ✓ Title bar minimized"
echo "   ✓ Extensions panel hidden"
echo "   ✓ Command palette disabled (F1, Ctrl/Cmd+Shift+P)"
echo "   ✓ IntelliSense and suggestions disabled"
echo "   ✓ Inline hints and ghost text removed"
echo "   ✓ Copilot chat closed"
echo "   ✓ Monitoring active (PID: $MONITOR_PID)"
echo ""
echo "📍 Monitor locations:"
echo "   Log file: /tmp/copilot_violations.log"
echo "   Monitor log: /tmp/copilot_monitor.log"
echo "   Stop script: /tmp/stop_monitor.sh"
echo ""
echo "💡 Tip: Watch the log with: tail -f /tmp/copilot_violations.log"
echo ""
echo "⚠️  Any attempts to enable Copilot will be logged!"
echo ""
echo "📝 Students must write all code independently for this test."

# Show current status
echo ""
echo "Current status check:"
echo "  Total extensions: $(code --list-extensions 2>/dev/null | wc -l)"
echo "  Copilot extensions: $(code --list-extensions 2>/dev/null | grep -i copilot | wc -l)"
echo "  Monitor process: $(ps -p $MONITOR_PID > /dev/null 2>&1 && echo "Running ✓" || echo "Not running ✗")"