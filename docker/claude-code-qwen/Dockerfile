FROM kasmweb/claude-code:1.19.0-rolling-weekly

USER root

# zstd required by Ollama installer; python3-pip for LiteLLM
RUN apt-get update && apt-get install -y --no-install-recommends zstd curl python3-pip && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install LiteLLM proxy (Anthropic API → Ollama bridge)
# Ubuntu Jammy pip 22.0.2 does not support --break-system-packages; not needed on Jammy anyway
RUN python3 -m pip install --no-cache-dir "litellm[proxy]>=1.40"

# Startup script: launches Ollama + LiteLLM, pulls model if missing, then hands off to bash
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

USER 1000
