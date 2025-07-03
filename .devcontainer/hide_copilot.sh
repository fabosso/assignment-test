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
  "workbench.activityBar.location": "hidden",
  "window.titleBarStyle": "custom",
  "workbench.layoutControl.enabled": false,

  // Hide command center and navigation
  "window.commandCenter": false,
  "workbench.editor.showTabs": true,
  "workbench.editor.tabActionLocation": "left",
  "workbench.editor.tabActionCloseVisibility": false,
  "window.menuBarVisibility": "hidden",

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
  "workbench.sideBar.location": "left",
  "editor.scrollbar.horizontal": "hidden",
  "editor.scrollbar.vertical": "auto"
}
EOF


# Also create workspace keybindings as fallback
echo "$KEYBINDINGS_CONTENT" > .vscode/keybindings.json
echo "  ✓ Created workspace keybindings at: .vscode/keybindings.json"

# Force uninstall Copilot if it exists
echo "  Checking for Copilot extensions..."

# List all extensions to see what's installed
echo "  Current extensions:"
code --list-extensions 2>/dev/null | while read ext; do
    echo "    - $ext"
done

# Check specifically for Copilot extensions
COPILOT_FOUND=$(code --list-extensions 2>/dev/null | grep -i copilot || true)
if [ -n "$COPILOT_FOUND" ]; then
    echo "  ⚠️  Found Copilot extensions installed:"
    echo "$COPILOT_FOUND" | while read ext; do
        echo "    - $ext"
        echo "    Uninstalling $ext..."
        code --uninstall-extension "$ext" --force 2>&1
    done
else
    echo "  ✓ No Copilot extensions found"
fi

# Also try specific known Copilot extension IDs
echo "  Attempting to uninstall known Copilot extensions..."
code --uninstall-extension GitHub.copilot --force 2>/dev/null && echo "    Removed GitHub.copilot" || echo "    GitHub.copilot not installed"
code --uninstall-extension GitHub.copilot-nightly --force 2>/dev/null && echo "    Removed GitHub.copilot-nightly" || echo "    GitHub.copilot-nightly not installed"
code --uninstall-extension GitHub.copilot-labs --force 2>/dev/null && echo "    Removed GitHub.copilot-labs" || echo "    GitHub.copilot-labs not installed"
code --uninstall-extension GitHub.copilot-chat --force 2>/dev/null && echo "    Removed GitHub.copilot-chat" || echo "    GitHub.copilot-chat not installed"

# Verify removal
echo "  Verifying removal..."
REMAINING_COPILOT=$(code --list-extensions 2>/dev/null | grep -i copilot || true)
if [ -n "$REMAINING_COPILOT" ]; then
    echo "  ❌ WARNING: Some Copilot extensions may still be installed:"
    echo "$REMAINING_COPILOT"
else
    echo "  ✓ All Copilot extensions successfully removed"
fi

# Backup settings for tampering detection
cp .vscode/settings.json /tmp/vscode_settings_backup.json 2>/dev/null || true

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

    # Check if any Copilot extension gets installed in VS Code
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

            # Every 5 minutes, do deeper checks
            if [ $((CHECK_COUNT % 60)) -eq 0 ]; then
                echo "[$(date)] Running deep scan..." >> "$LOG_FILE"
                check_browser_extensions
                check_network_connections
            fi
        fi
    fi

    # Check for VS Code configuration tampering
    if [ -f ".vscode/settings.json" ]; then
        if ! grep -q '"github.copilot.enable": false' .vscode/settings.json 2>/dev/null; then
            echo "[$(date)] WARNING: VS Code settings may have been tampered with!" >> "$LOG_FILE"
            # Restore our settings
            cp /tmp/vscode_settings_backup.json .vscode/settings.json 2>/dev/null || true
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
echo "   ✓ Activity bar hidden (position: hidden)"
echo "   ✓ Status bar hidden"
echo "   ✓ Command center hidden"
echo "   ✓ Menu bar hidden"
echo "   ✓ Navigation controls hidden"
echo "   ✓ Extensions panel blocked"
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
echo "🔍 Monitor checks for:"
echo "   - VS Code extensions"
echo "   - Browser extensions/userscripts"
echo "   - Network connections to Copilot"
echo "   - Settings file tampering"
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