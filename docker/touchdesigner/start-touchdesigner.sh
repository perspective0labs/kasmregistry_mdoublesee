#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY="${DISPLAY:-:1}"
export WINEPREFIX="${WINEPREFIX:-/home/kasm-user/.wine-touchdesigner}"
export TOUCHDESIGNER_PROJECTS="${TOUCHDESIGNER_PROJECTS:-/home/kasm-user/Documents/TouchDesigner}"
mkdir -p "$WINEPREFIX" "$TOUCHDESIGNER_PROJECTS" /opt/touchdesigner-installer
WINE_BIN="${WINE_BIN:-$(command -v wine || command -v wine64 || true)}"
WINEBOOT_BIN="${WINEBOOT_BIN:-$(command -v wineboot || true)}"
if [ -z "$WINE_BIN" ]; then
  echo "Wine launcher not found. Rebuild image with wine/wine64 installed." >&2
  exit 127
fi

log=/tmp/touchdesigner-kasm.log
{
  echo "TouchDesigner Kasm startup: $(date -Is)"
  echo "WINEPREFIX=$WINEPREFIX"
  echo "TOUCHDESIGNER_PROJECTS=$TOUCHDESIGNER_PROJECTS"
} >> "$log"

find_touchdesigner_exe() {
  find "$WINEPREFIX/drive_c" -iname 'TouchDesigner*.exe' -type f 2>/dev/null | head -1 || true
}

TD_EXE="${TOUCHDESIGNER_EXE:-}"
if [ -z "$TD_EXE" ]; then TD_EXE="$(find_touchdesigner_exe)"; fi

if [ -n "$TD_EXE" ] && [ -f "$TD_EXE" ]; then
  echo "Launching TouchDesigner: $TD_EXE" >> "$log"
  exec "$WINE_BIN" "$TD_EXE"
fi

installer=""
for p in /opt/touchdesigner-installer/TouchDesigner*.exe /opt/touchdesigner-installer/*TouchDesigner*.exe /opt/touchdesigner-installer/TouchDesigner.exe; do
  [ -f "$p" ] && installer="$p" && break
done

if [ -z "$installer" ] && [ -n "${TOUCHDESIGNER_INSTALLER_URL:-}" ]; then
  installer=/tmp/TouchDesigner-installer.exe
  echo "Downloading TouchDesigner installer from TOUCHDESIGNER_INSTALLER_URL" >> "$log"
  curl -L --fail --retry 3 --connect-timeout 20 -o "$installer" "$TOUCHDESIGNER_INSTALLER_URL" || installer=""
fi

if [ -n "$installer" ] && [ -f "$installer" ]; then
  echo "Running installer: $installer" >> "$log"
  [ -n "$WINEBOOT_BIN" ] && "$WINEBOOT_BIN" -u || true
  "$WINE_BIN" "$installer" || true
  TD_EXE="$(find_touchdesigner_exe)"
  if [ -n "$TD_EXE" ] && [ -f "$TD_EXE" ]; then
    exec "$WINE_BIN" "$TD_EXE"
  fi
fi

cat > /tmp/touchdesigner-first-run.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>TouchDesigner Kasm Workspace</title><style>body{font-family:Inter,Arial,sans-serif;background:#111827;color:#f9fafb;margin:3rem;line-height:1.5}code{background:#374151;padding:.15rem .35rem;border-radius:.3rem}a{color:#38bdf8}.card{max-width:900px;background:#1f2937;padding:2rem;border-radius:1rem;box-shadow:0 20px 50px #0008}</style></head><body><div class="card"><h1>TouchDesigner Kasm workspace</h1><p>This is the Perspective Labs convertible TouchDesigner container.</p><ol><li>Download TouchDesigner from <a href="https://derivative.ca/download">Derivative</a>.</li><li>Place the Windows installer in the mounted persistent folder as <code>/opt/touchdesigner-installer/TouchDesigner.exe</code>, or set <code>TOUCHDESIGNER_INSTALLER_URL</code>.</li><li>Restart this workspace. The startup hook will install/run it under Wine.</li></ol><p>Projects persist at <code>~/Documents/TouchDesigner</code>. Wine prefix persists at <code>~/.wine-touchdesigner</code>.</p><p>For Hermes control, install twozero MCP inside TouchDesigner after first launch.</p></div></body></html>
HTML

if command -v chromium-browser >/dev/null 2>&1; then
  exec chromium-browser --no-sandbox --disable-dev-shm-usage --app=file:///tmp/touchdesigner-first-run.html
elif command -v google-chrome >/dev/null 2>&1; then
  exec google-chrome --no-sandbox --disable-dev-shm-usage --app=file:///tmp/touchdesigner-first-run.html
else
  xterm -e "less $log" || tail -f "$log"
fi
