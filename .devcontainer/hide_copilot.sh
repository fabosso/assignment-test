#!/bin/bash

echo "🔒 Configuring environment for secure online test..."

# Wait for VS Code to be ready
sleep 3

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

# Create a monitoring script for the test duration
cat > "$HOME/.test_monitor.sh" << 'EOF'
#!/bin/bash
# Monitor and prevent Copilot during test

while true; do
    # Check if any Copilot extension gets installed
    if code --list-extensions 2>/dev/null | grep -i copilot; then
        echo "[$(date)] WARNING: Copilot detected during test! Removing..."
        code --list-extensions 2>/dev/null | grep -i copilot | xargs -I {} code --uninstall-extension {} --force 2>/dev/null || true

        # Log this violation
        echo "[$(date)] VIOLATION: Attempted to use Copilot during test" >> "$HOME/test_violations.log"
    fi

    sleep 10
done
EOF

chmod +x "$HOME/.test_monitor.sh"
nohup "$HOME/.test_monitor.sh" > "$HOME/.test_monitor.log" 2>&1 &
MONITOR_PID=$!

echo "✅ Test environment configured!"
echo ""
echo "🔒 ONLINE TEST MODE ACTIVE:"
echo "   ✓ Copilot completely disabled"
echo "   ✓ All AI assistance blocked"
echo "   ✓ Extensions panel hidden"
echo "   ✓ Command palette disabled (F1, Ctrl/Cmd+Shift+P)"
echo "   ✓ IntelliSense and suggestions disabled"
echo "   ✓ Monitoring active (PID: $MONITOR_PID)"
echo ""
echo "⚠️  Any attempts to enable Copilot will be logged to ~/test_violations.log"
echo ""
echo "📝 Students must write all code independently for this test."