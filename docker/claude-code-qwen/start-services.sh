#!/usr/bin/env bash
set -euo pipefail

MODEL="${OLLAMA_MODEL:-qwen2.5-coder:7b}"

echo ">>> Starting Ollama..."
OLLAMA_HOST=127.0.0.1:11434 ollama serve > /tmp/ollama.log 2>&1 &

# Wait for Ollama to be ready
for i in $(seq 1 30); do
  curl -sf http://127.0.0.1:11434/ > /dev/null 2>&1 && break
  sleep 1
done

echo ">>> Pulling $MODEL (skipped if already cached)..."
ollama pull "$MODEL"

echo ">>> Starting LiteLLM proxy on :4001..."
litellm --model "ollama/$MODEL" --port 4001 > /tmp/litellm.log 2>&1 &

# Wait for LiteLLM
for i in $(seq 1 15); do
  curl -sf http://127.0.0.1:4001/health > /dev/null 2>&1 && break
  sleep 1
done

echo ">>> Ready. ANTHROPIC_BASE_URL=http://localhost:4001"
exec bash
