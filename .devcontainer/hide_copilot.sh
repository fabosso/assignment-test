#!/bin/bash

echo "🔒 Hiding Copilot icon and status bar..."

# Wait for VS Code to be ready
sleep 3

# Create VS Code settings to hide UI elements
echo "  Creating VS Code settings..."
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  // Hide auxiliary bar where Copilot icon appears
  "workbench.auxiliaryBar.enabled": false,
  "workbench.auxiliaryBar.visible": false,

  // Hide the entire status bar
  "workbench.statusBar.visible": false,

  // Hide Extensions icon from activity bar
  "workbench.activityBar.visible": true,
  "workbench.view.extensions.visible": false
}
EOF

echo "✅ Configuration complete!"

# Create keybindings to disable shortcuts
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
  }
]
EOF

echo ""
echo "📌 UI Changes:"
echo "   - Copilot icon panel: Hidden"
echo "   - Status bar: Hidden"
echo "   - Extensions button: Hidden"
echo ""
echo "🔒 Disabled Keybindings:"
echo "   - Ctrl/Cmd+Shift+X: Extensions panel"
echo "   - Ctrl/Cmd+I: Copilot chat"
echo "   - Ctrl/Cmd+Enter: Copilot generate"
echo "   - Tab: Accept Copilot suggestion"
echo "   - Alt+\\: Toggle Copilot"
echo "   - Alt+[/]: Previous/Next suggestion"
echo ""
