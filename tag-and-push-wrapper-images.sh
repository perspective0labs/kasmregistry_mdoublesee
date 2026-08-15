#!/usr/bin/env bash
set -euo pipefail
pairs=(
  'anythingllm|kasmweb/ubuntu-noble-anythingllm:1.19.0-rolling-weekly'
  'audacity|kasmweb/audacity:1.19.0-rolling-weekly'
  'brave|kasmweb/brave:1.19.0-rolling-weekly'
  'kali-linux|kasmweb/kali-rolling-desktop:1.19.0-rolling-weekly'
  'kasmos|kasmweb/kasmos-desktop:1.19.0-rolling-weekly'
  'obsidian|kasmweb/obsidian:1.19.0-rolling-weekly'
  'retroarch|kasmweb/retroarch:1.19.0-rolling-weekly'
  'signal|kasmweb/signal:1.19.0-rolling-weekly'
  'telegram|kasmweb/telegram:1.19.0-rolling-weekly'
  'terminal|kasmweb/terminal:1.19.0-rolling-weekly'
  'vlc|kasmweb/vlc:1.19.0-rolling-weekly'
  'vs-code|kasmweb/vs-code:1.19.0-rolling-weekly'
)
for pair in "${pairs[@]}"; do
  name="${pair%%|*}"
  base="${pair#*|}"
  target="ghcr.io/perspective0labs/${name}:latest"
  echo "=== ${target} <= ${base} ==="
  docker image inspect "$base" >/dev/null 2>&1 || docker pull "$base"
  docker tag "$base" "$target"
  docker push "$target"
  docker manifest inspect "$target" >/dev/null
  echo "OK ${target}"
done
