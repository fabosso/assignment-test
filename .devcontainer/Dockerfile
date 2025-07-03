FROM mcr.microsoft.com/devcontainers/python:1-3.11-bullseye
USER root
RUN apt-get update && apt-get install -y flake8 && rm -rf /var/lib/apt/lists/*
USER vscode
RUN echo '#!/bin/bash' > /home/vscode/monitor-extensions.sh \
 && echo 'while true; do pkill -f "copilot"; rm -rf $HOME/.vscode-server/extensions/*copilot*; sleep 10; done' >> /home/vscode/monitor-extensions.sh \
 && chmod +x /home/vscode/monitor-extensions.sh
ENV GITHUB_COPILOT_ENABLED=false
RUN mkdir -p /home/vscode/.local/bin && \
    echo '#!/bin/bash' > /home/vscode/.local/bin/code && \
    echo 'if [[ "$@" == *"--install-extension"* ]] && [[ "$@" == *"copilot"* ]]; then' >> /home/vscode/.local/bin/code && \
    echo '  echo "❌ GitHub Copilot is blocked"; exit 1' >> /home/vscode/.local/bin/code && \
    echo 'fi' >> /home/vscode/.local/bin/code && \
    echo '/usr/bin/code "$@"' >> /home/vscode/.local/bin/code && \
    chmod +x /home/vscode/.local/bin/code