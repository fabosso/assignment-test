#!/bin/bash

echo "🔒 Configuring UI to hide Copilot..."

# Install flake8 first
pip install flake8

# Wait for VS Code to be ready
sleep 3

# Method 1: Try to use VS Code commands to hide Copilot
echo "  Attempting to hide Copilot via VS Code commands..."

# These commands simulate clicking "Hide Copilot" in the UI
code --command workbench.action.auxiliary.resetDefaultLocation 2>/dev/null || true
code --command workbench.action.toggleAuxiliaryBar 2>/dev/null || true
code --command workbench.action.activityBarLocation.hide 2>/dev/null || true

# Method 2: Create comprehensive settings to disable Copilot UI
echo "  Updating VS Code settings..."
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  // Disable ALL Copilot features
  "github.copilot.enable": false,
  "github.copilot.advanced": {
    "disabled": true
  },
  "github.copilot.chat.enabled": false,
  "github.copilot.voice.enabled": false,
  "github.copilot.editor.enableAutoCompletions": false,

  // Hide Copilot from UI
  "workbench.panel.chat.hidden": true,
  "chat.commandCenter.enabled": false,

  // Minimal Python settings
  "python.defaultInterpreterPath": "/usr/local/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": false,
  "python.linting.flake8Enabled": true,

  // Disable all telemetry and extras
  "telemetry.telemetryLevel": "off",
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "extensions.ignoreRecommendations": true,

  // Clean editor
  "editor.minimap.enabled": false,
  "editor.suggestOnTriggerCharacters": false,
  "editor.quickSuggestions": {
    "other": false,
    "comments": false,
    "strings": false
  },

  // Hide auxiliary bar where Copilot chat appears
  "workbench.auxiliaryBar.enabled": false,
  "workbench.auxiliaryBar.visible": false
}
EOF

# Method 3: Create a keybinding that disables Copilot shortcuts
echo "  Creating keybinding overrides..."
mkdir -p .vscode
cat > .vscode/keybindings.json << 'EOF'
[
  {
    "key": "ctrl+enter",
    "command": "-github.copilot.generate",
    "when": "editorTextFocus && github.copilot.activated"
  },
  {
    "key": "ctrl+shift+i",
    "command": "-workbench.action.chat.open",
    "when": "github.copilot.activated"
  }
]
EOF

echo "✅ Configuration complete!"
echo ""
echo "📌 If you still see Copilot icons:"
echo "   1. Right-click on the Copilot icon in the sidebar"
echo "   2. Select 'Hide Copilot' or 'Hide from Activity Bar'"
echo "   3. Or reload the window: Ctrl/Cmd + R"
echo ""
echo "🚫 Copilot has been disabled in all settings"