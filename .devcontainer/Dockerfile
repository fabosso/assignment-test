FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3.11 \
    python3-pip \
    python3.11-venv \
    wget \
    sudo \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Create non-root user (required for VS Code)
RUN useradd -m -s /bin/bash -G sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install VS Code Server dependencies
RUN apt-get update && apt-get install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libgtk-3-0 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Switch to vscode user
USER vscode
WORKDIR /home/vscode

# Set up Python environment
ENV PATH="/home/vscode/.local/bin:${PATH}"
RUN python3.11 -m pip install --user --upgrade pip && \
    python3.11 -m pip install --user \
    flake8 \
    pylint \
    black \
    pytest

# Pre-create VS Code directories with restrictions
RUN mkdir -p /home/vscode/.vscode-server/extensions && \
    mkdir -p /home/vscode/.vscode-server/data/Machine && \
    mkdir -p /home/vscode/.config/Code/User

# Create restricted settings that will be applied
RUN echo '{ \
    "github.copilot.enable": {"*": false}, \
    "github.copilot.inlineSuggest.enable": false, \
    "github.copilot.chat.enabled": false, \
    "extensions.autoUpdate": false, \
    "extensions.autoCheckUpdates": false \
}' > /home/vscode/.vscode-server/data/Machine/settings.json

# Alternative: Create script with echo commands
RUN echo '#!/bin/bash' > /home/vscode/monitor-extensions.sh && \
    echo 'ALLOWED_EXTENSIONS="ms-python.python ms-python.vscode-pylance ms-python.flake8"' >> /home/vscode/monitor-extensions.sh && \
    echo 'BLOCKED_KEYWORDS="copilot tabnine codeium intellicode kite tabby"' >> /home/vscode/monitor-extensions.sh && \
    echo '' >> /home/vscode/monitor-extensions.sh && \
    echo 'while true; do' >> /home/vscode/monitor-extensions.sh && \
    echo '    if [ -d "/home/vscode/.vscode-server/extensions" ]; then' >> /home/vscode/monitor-extensions.sh && \
    echo '        for ext_dir in /home/vscode/.vscode-server/extensions/*; do' >> /home/vscode/monitor-extensions.sh && \
    echo '            if [ -d "$ext_dir" ]; then' >> /home/vscode/monitor-extensions.sh && \
    echo '                ext_name=$(basename "$ext_dir" | tr "[:upper:]" "[:lower:]")' >> /home/vscode/monitor-extensions.sh && \
    echo '                for blocked in $BLOCKED_KEYWORDS; do' >> /home/vscode/monitor-extensions.sh && \
    echo '                    if [[ "$ext_name" == *"$blocked"* ]]; then' >> /home/vscode/monitor-extensions.sh && \
    echo '                        echo "[$(date)] Removing blocked extension: $ext_name"' >> /home/vscode/monitor-extensions.sh && \
    echo '                        rm -rf "$ext_dir"' >> /home/vscode/monitor-extensions.sh && \
    echo '                    fi' >> /home/vscode/monitor-extensions.sh && \
    echo '                done' >> /home/vscode/monitor-extensions.sh && \
    echo '            fi' >> /home/vscode/monitor-extensions.sh && \
    echo '        done' >> /home/vscode/monitor-extensions.sh && \
    echo '    fi' >> /home/vscode/monitor-extensions.sh && \
    echo '    pkill -f "copilot" 2>/dev/null || true' >> /home/vscode/monitor-extensions.sh && \
    echo '    sleep 10' >> /home/vscode/monitor-extensions.sh && \
    echo 'done' >> /home/vscode/monitor-extensions.sh

RUN chmod +x /home/vscode/monitor-extensions.sh

# Create startup script
RUN echo '#!/bin/bash' > /home/vscode/startup.sh && \
    echo '' >> /home/vscode/startup.sh && \
    echo '# Start the monitor in background' >> /home/vscode/startup.sh && \
    echo '/home/vscode/monitor-extensions.sh &' >> /home/vscode/startup.sh && \
    echo '' >> /home/vscode/startup.sh && \
    echo '# Show warning message' >> /home/vscode/startup.sh && \
    echo 'echo "================================================"' >> /home/vscode/startup.sh && \
    echo 'echo "🚫 AI CODING ASSISTANTS ARE DISABLED"' >> /home/vscode/startup.sh && \
    echo 'echo "================================================"' >> /home/vscode/startup.sh && \
    echo 'echo "This is an educational environment."' >> /home/vscode/startup.sh && \
    echo 'echo "GitHub Copilot and similar tools are blocked."' >> /home/vscode/startup.sh && \
    echo 'echo "You must write all code yourself!"' >> /home/vscode/startup.sh && \
    echo 'echo "================================================"' >> /home/vscode/startup.sh && \
    echo '' >> /home/vscode/startup.sh && \
    echo '# Create a canary file to detect if extensions are being installed' >> /home/vscode/startup.sh && \
    echo 'touch /home/vscode/.extension-check' >> /home/vscode/startup.sh && \
    echo '' >> /home/vscode/startup.sh && \
    echo '# Set restrictive permissions on extension directories after VS Code starts' >> /home/vscode/startup.sh && \
    echo '(sleep 30 && chmod 555 /home/vscode/.vscode-server/extensions 2>/dev/null) &' >> /home/vscode/startup.sh

RUN chmod +x /home/vscode/startup.sh

# Set environment variables to disable telemetry and copilot
ENV GITHUB_COPILOT_ENABLED=false \
    GITHUB_COPILOT_CHAT_ENABLED=false \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    HOMEBREW_NO_ANALYTICS=1

# Create a fake 'code' command that blocks extension installation
RUN mkdir -p /home/vscode/.local/bin && \
    echo '#!/bin/bash' > /home/vscode/.local/bin/code && \
    echo 'if [[ "$*" == *"--install-extension"* ]] && [[ "$*" == *"copilot"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '    echo "❌ GitHub Copilot is blocked in this educational environment"' >> /home/vscode/.local/bin/code && \
    echo '    exit 1' >> /home/vscode/.local/bin/code && \
    echo 'elif [[ "$*" == *"--install-extension"* ]] && [[ "$*" == *"tabnine"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '    echo "❌ AI assistants are blocked in this educational environment"' >> /home/vscode/.local/bin/code && \
    echo '    exit 1' >> /home/vscode/.local/bin/code && \
    echo 'elif [[ "$*" == *"--install-extension"* ]] && [[ "$*" == *"codeium"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '    echo "❌ AI assistants are blocked in this educational environment"' >> /home/vscode/.local/bin/code && \
    echo '    exit 1' >> /home/vscode/.local/bin/code && \
    echo 'elif [[ "$*" == *"--install-extension"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '    echo "⚠️  Extension installation is restricted. Contact your instructor if you need additional tools."' >> /home/vscode/.local/bin/code && \
    echo '    exit 1' >> /home/vscode/.local/bin/code && \
    echo 'else' >> /home/vscode/.local/bin/code && \
    echo '    /usr/bin/code "$@" 2>/dev/null || true' >> /home/vscode/.local/bin/code && \
    echo 'fi' >> /home/vscode/.local/bin/code

RUN chmod +x /home/vscode/.local/bin/code

# Ensure our fake 'code' command is used
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Final setup
CMD ["/bin/bash", "/home/vscode/startup.sh"]