FROM kasmweb/claude-code:1.19.0-rolling-weekly

USER root

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install LiteLLM proxy (Anthropic API → Ollama bridge)
RUN pip3 install --no-cache-dir "litellm[proxy]>=1.40"

# Startup script: launches Ollama + LiteLLM, pulls model if missing, then hands off to bash
COPY start-services.sh /usr/local/bin/start-services.sh
RUN chmod +x /usr/local/bin/start-services.sh

USER 1000
