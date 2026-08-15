#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY="${DISPLAY:-:1}"
HOST="${TOUCHDESIGNER_STREAM_HOST:-}"
PORT="${TOUCHDESIGNER_STREAM_PORT:-3389}"
USER_NAME="${TOUCHDESIGNER_STREAM_USER:-}"
MODE="${TOUCHDESIGNER_STREAM_MODE:-rdp}"
LOG=/tmp/touchdesigner-stream-kasm.log
{
  echo "TouchDesigner stream launcher: $(date -Is)"
  echo "MODE=$MODE HOST=$HOST PORT=$PORT USER=$USER_NAME"
} >> "$LOG"
if [ -z "$HOST" ]; then
  msg="TouchDesigner is configured as a Windows-VM streaming workspace. Set TOUCHDESIGNER_STREAM_HOST to the Windows VM/RDP host once the VPS VM is installed."
  echo "$msg" | tee -a "$LOG"
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --width=560 --title="TouchDesigner Stream" --text="$msg" || true
  fi
  exec bash -lc 'sleep infinity'
fi
if [ "$MODE" = "rdp" ]; then
  args=(/v:"$HOST:$PORT" /dynamic-resolution /cert:ignore /sound /microphone /clipboard)
  if [ -n "$USER_NAME" ]; then args+=(/u:"$USER_NAME"); fi
  exec xfreerdp "${args[@]}"
fi
if [ "$MODE" = "vnc" ]; then
  exec remmina -c "vnc://$HOST:$PORT"
fi
echo "Unsupported TOUCHDESIGNER_STREAM_MODE=$MODE" | tee -a "$LOG"
exit 2
