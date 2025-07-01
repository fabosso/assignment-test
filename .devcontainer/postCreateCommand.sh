#!/bin/bash

echo "🔒 Setting up restricted environment..."

# Start the monitoring script
/home/vscode/scripts/monitor-extensions.sh &
disown

# Install Python packages
if [ -f "/workspaces/${GITHUB_REPOSITORY##*/}/requirements.txt" ]; then
    echo "📦 Installing Python requirements..."
    pip install -r "/workspaces/${GITHUB_REPOSITORY##*/}/requirements.txt"
fi

# Create environment check script
cat > /workspaces/${GITHUB_REPOSITORY##*/}/check_environment.py << 'EOF'
#!/usr/bin/env python3
import os
import subprocess

print("🔍 Checking Environment Status...\n")

# Check for AI-related environment variables
copilot_enabled = os.environ.get("GITHUB_COPILOT_ENABLED", "not set")
if copilot_enabled.lower() == "false":
    print("✅ GitHub Copilot is disabled")
else:
    print("❌ GitHub Copilot might be enabled")

# Check for running AI processes
try:
    result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
    ai_processes = ["copilot", "tabnine", "codeium", "kite"]
    found = [p for p in ai_processes if p in result.stdout.lower()]
    if found:
        print(f"❌ Found AI processes: {', '.join(found)}")
    else:
        print("✅ No AI processes detected")
except:
    print("✅ Process check complete")

print("\n📚 Environment Rules:")
print("- AI code completion is BLOCKED")
print("- You must write all code yourself")
print("- Syntax checking and linting are enabled")
EOF

chmod +x /workspaces/${GITHUB_REPOSITORY##*/}/check_environment.py
python3 /workspaces/${GITHUB_REPOSITORY##*/}/check_environment.py

echo -e "\n✅ Environment setup complete!"