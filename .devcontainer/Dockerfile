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

# Create a script to monitor and remove unwanted extensions
RUN cat > /home/vscode/monitor-extensions.sh << 'EOF'
#!/bin/bash
ALLOWED_EXTENSIONS="ms-python.python ms-python.vscode-pylance ms-python.flake8"
BLOCKED_KEYWORDS="copilot tabnine codeium intellicode kite tabby"

while true; do
    # Check VS Code Server extensions directory
    if [ -d "/home/vscode/.vscode-server/extensions" ]; then
        for ext_dir in /home/vscode/.vscode-server/extensions/*; do
            if [ -d "$ext_dir" ]; then
                ext_name=$(basename "$ext_dir" | tr '[:upper:]' '[:lower:]')

                # Check if extension is in blocked list
                for blocked in $BLOCKED_KEYWORDS; do
                    if [[ "$ext_name" == *"$blocked"* ]]; then
                        echo "[$(date)] Removing blocked extension: $ext_name"
                        rm -rf "$ext_dir"
                    fi
                done

                # Check if extension is not in allowed list
                allowed=false
                for allowed_ext in $ALLOWED_EXTENSIONS; do
                    if [[ "$ext_name" == *"$allowed_ext"* ]]; then
                        allowed=true
                        break
                    fi
                done

                if [ "$allowed" = false ] && [[ ! "$ext_name" == ms-vscode* ]]; then
                    echo "[$(date)] Removing unauthorized extension: $ext_name"
                    rm -rf "$ext_dir"
                fi
            fi
        done
    fi

    # Kill any Copilot processes
    pkill -f "copilot" 2>/dev/null || true
    pkill -f "tabnine" 2>/dev/null || true
    pkill -f "codeium" 2>/dev/null || true

    sleep 10
done
EOF

RUN chmod +x /home/vscode/monitor-extensions.sh

# Create startup script
RUN cat > /home/vscode/startup.sh << 'EOF'
#!/bin/bash

# Start the monitor in background
/home/vscode/monitor-extensions.sh &

# Show warning message
echo "================================================"
echo "🚫 AI CODING ASSISTANTS ARE DISABLED"
echo "================================================"
echo "This is an educational environment."
echo "GitHub Copilot and similar tools are blocked."
echo "You must write all code yourself!"
echo "================================================"

# Create a canary file to detect if extensions are being installed
touch /home/vscode/.extension-check

# Set restrictive permissions on extension directories after VS Code starts
(sleep 30 && chmod 555 /home/vscode/.vscode-server/extensions 2>/dev/null) &

EOF

RUN chmod +x /home/vscode/startup.sh

# Set environment variables to disable telemetry and copilot
ENV GITHUB_COPILOT_ENABLED=false \
    GITHUB_COPILOT_CHAT_ENABLED=false \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    HOMEBREW_NO_ANALYTICS=1

# Create a fake 'code' command that blocks extension installation
RUN mkdir -p /home/vscode/.local/bin && \
    cat > /home/vscode/.local/bin/code << 'EOF'
#!/bin/bash
if [[ "$*" == *"--install-extension"* ]] && [[ "$*" == *"copilot"* ]]; then
    echo "❌ GitHub Copilot is blocked in this educational environment"
    exit 1
elif [[ "$*" == *"--install-extension"* ]] && [[ "$*" == *"tabnine"* ]]; then
    echo "❌ AI assistants are blocked in this educational environment"
    exit 1
elif [[ "$*" == *"--install-extension"* ]] && [[ "$*" == *"codeium"* ]]; then
    echo "❌ AI assistants are blocked in this educational environment"
    exit 1
elif [[ "$*" == *"--install-extension"* ]]; then
    echo "⚠️  Extension installation is restricted. Contact your instructor if you need additional tools."
    exit 1
else
    /usr/bin/code "$@" 2>/dev/null || true
fi
EOF

RUN chmod +x /home/vscode/.local/bin/code

# Ensure our fake 'code' command is used
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Final setup
CMD ["/bin/bash", "/home/vscode/startup.sh"]