#!/bin/bash

echo "🔒 Setting up restricted environment..."

# Install Python packages if requirements.txt exists
if [ -f "/workspace/requirements.txt" ]; then
    echo "📦 Installing Python requirements..."
    pip install -r /workspace/requirements.txt
fi

# Start extension monitor
nohup /home/vscode/monitor-extensions.sh > /home/vscode/extension-monitor.log 2>&1 &

# Create a status check script for students
cat > /workspace/check_environment.py << 'EOF'
#!/usr/bin/env python3
import os
import subprocess
import sys

print("🔍 Checking Environment Status...\n")

# Check for AI-related environment variables
ai_vars = ["GITHUB_COPILOT_ENABLED", "COPILOT_ENABLED"]
for var in ai_vars:
    value = os.environ.get(var, "not set")
    status = "✅" if value.lower() in ["false", "not set"] else "❌"
    print(f"{status} {var}: {value}")

# Check for running AI processes
ai_processes = ["copilot", "tabnine", "codeium", "kite"]
found_processes = []

try:
    result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
    for proc in ai_processes:
        if proc.lower() in result.stdout.lower():
            found_processes.append(proc)
except:
    pass

if found_processes:
    print(f"\n❌ Found AI processes running: {', '.join(found_processes)}")
else:
    print("\n✅ No AI processes detected")

print("\n📚 Environment Rules:")
print("- GitHub Copilot is DISABLED")
print("- AI code completion is BLOCKED")
print("- You must write all code yourself")
print("- Syntax checking and linting are enabled")
print("\nGood luck with your assignment! 💪")
EOF

chmod +x /workspace/check_environment.py

# Run the check
python3 /workspace/check_environment.py

echo -e "\n✅ Environment setup complete!"