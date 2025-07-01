# Use the official Python devcontainer image as base
FROM mcr.microsoft.com/devcontainers/python:1-3.11-bullseye

# Switch to root for installations
USER root

# Install additional tools
RUN apt-get update && apt-get install -y \
    flake8 \
    && rm -rf /var/lib/apt/lists/*

# Switch back to vscode user
USER vscode

# Install Python packages
RUN pip3 --disable-pip-version-check --no-cache-dir install \
    pylint \
    black \
    pytest

# Create monitoring script
RUN mkdir -p /home/vscode/scripts && \
    echo '#!/bin/bash' > /home/vscode/scripts/monitor-extensions.sh && \
    echo 'BLOCKED="copilot tabnine codeium intellicode kite"' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo 'while true; do' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '  for keyword in $BLOCKED; do' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '    pkill -f "$keyword" 2>/dev/null' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '  done' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '  if [ -d "$HOME/.vscode-server/extensions" ]; then' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '    find "$HOME/.vscode-server/extensions" -type d -iname "*copilot*" -exec rm -rf {} + 2>/dev/null' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '    find "$HOME/.vscode-server/extensions" -type d -iname "*tabnine*" -exec rm -rf {} + 2>/dev/null' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '    find "$HOME/.vscode-server/extensions" -type d -iname "*codeium*" -exec rm -rf {} + 2>/dev/null' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '  fi' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo '  sleep 10' >> /home/vscode/scripts/monitor-extensions.sh && \
    echo 'done' >> /home/vscode/scripts/monitor-extensions.sh && \
    chmod +x /home/vscode/scripts/monitor-extensions.sh

# Create startup script
RUN echo '#!/bin/bash' > /home/vscode/startup.sh && \
    echo 'echo "================================================"' >> /home/vscode/startup.sh && \
    echo 'echo "🚫 AI CODING ASSISTANTS ARE DISABLED"' >> /home/vscode/startup.sh && \
    echo 'echo "================================================"' >> /home/vscode/startup.sh && \
    echo 'echo "This is an educational environment."' >> /home/vscode/startup.sh && \
    echo 'echo "GitHub Copilot and similar tools are blocked."' >> /home/vscode/startup.sh && \
    echo 'echo "================================================"' >> /home/vscode/startup.sh && \
    echo '/home/vscode/scripts/monitor-extensions.sh &' >> /home/vscode/startup.sh && \
    echo 'disown' >> /home/vscode/startup.sh && \
    chmod +x /home/vscode/startup.sh

# Set environment variables
ENV GITHUB_COPILOT_ENABLED=false \
    GITHUB_COPILOT_CHAT_ENABLED=false \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# Create override for code command
RUN mkdir -p /home/vscode/.local/bin && \
    echo '#!/bin/bash' > /home/vscode/.local/bin/code && \
    echo 'if [[ "$@" == *"--install-extension"* ]] && [[ "$@" == *"copilot"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '  echo "❌ GitHub Copilot is blocked in this educational environment"' >> /home/vscode/.local/bin/code && \
    echo '  exit 1' >> /home/vscode/.local/bin/code && \
    echo 'fi' >> /home/vscode/.local/bin/code && \
    echo 'if [[ "$@" == *"--install-extension"* ]] && [[ "$@" == *"tabnine"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '  echo "❌ AI assistants are blocked in this educational environment"' >> /home/vscode/.local/bin/code && \
    echo '  exit 1' >> /home/vscode/.local/bin/code && \
    echo 'fi' >> /home/vscode/.local/bin/code && \
    echo 'if command -v /usr/bin/code >/dev/null 2>&1; then' >> /home/vscode/.local/bin/code && \
    echo '  /usr/bin/code "$@"' >> /home/vscode/.local/bin/code && \
    echo 'else' >> /home/vscode/.local/bin/code && \
    echo '  echo "VS Code command not found"' >> /home/vscode/.local/bin/code && \
    echo 'fi' >> /home/vscode/.local/bin/code && \
    chmod +x /home/vscode/.local/bin/code

# Update PATH
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Pre-create VS Code directories with settings
RUN mkdir -p /home/vscode/.vscode-server/data/Machine && \
    echo '{ \
    "github.copilot.enable": {"*": false}, \
    "github.copilot.inlineSuggest.enable": false, \
    "github.copilot.chat.enabled": false, \
    "extensions.autoUpdate": false, \
    "extensions.autoCheckUpdates": false \
}' > /home/vscode/.vscode-server/data/Machine/settings.json