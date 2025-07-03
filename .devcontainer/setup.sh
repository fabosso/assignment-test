#!/bin/bash
set -e

echo "🚀 Setting up Python environment..."

# Install Python dependencies
pip install -r requirements.txt

# Install pre-commit hooks
pre-commit install

echo "🔒 Removing GitHub Copilot..."

# Force uninstall all Copilot-related extensions
code --uninstall-extension GitHub.copilot --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-nightly --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-labs --force 2>/dev/null || true
code --uninstall-extension GitHub.copilot-chat --force 2>/dev/null || true

# Wait a moment for VS Code to process
sleep 2

# Create a VS Code settings file that blocks Copilot
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  "github.copilot.enable": false,
  "github.copilot.advanced": {
    "disabled": true
  },
  "extensions.ignoreRecommendations": true,
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false
}
EOF

# Create a script to continuously monitor and remove Copilot
cat > /tmp/block_copilot.sh << 'EOF'
#!/bin/bash
while true; do
    # Check if Copilot is installed and remove it
    if code --list-extensions 2>/dev/null | grep -i copilot; then
        echo "Copilot detected, removing..."
        code --uninstall-extension GitHub.copilot --force 2>/dev/null || true
        code --uninstall-extension GitHub.copilot-nightly --force 2>/dev/null || true
        code --uninstall-extension GitHub.copilot-labs --force 2>/dev/null || true
        code --uninstall-extension GitHub.copilot-chat --force 2>/dev/null || true
    fi
    sleep 30
done
EOF

chmod +x /tmp/block_copilot.sh

# Run the monitor in the background
nohup /tmp/block_copilot.sh > /tmp/copilot_monitor.log 2>&1 &

echo "✅ Setup complete! Copilot has been removed and blocked."
echo ""
echo "⚠️  IMPORTANT: If you see any Copilot icons or features:"
echo "   1. Refresh your browser (Ctrl/Cmd + R)"
echo "   2. If it persists, restart the Codespace"
echo ""
echo "📝 You can verify Copilot is disabled by running:"
echo "   python validate_setup.py"