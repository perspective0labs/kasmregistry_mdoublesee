#!/usr/bin/env bash
set -euo pipefail

APP_FLAVOUR="${GRANDMA_FLAVOUR:-grandMA}"
APP_EXE="${GRANDMA_EXE:-}"
INSTALLER_DIR="${GRANDMA_INSTALLER_DIR:-/home/kasm-user/grandma-installers}"
DOC_DIR="/home/kasm-user/Documents/grandMA"
mkdir -p "$INSTALLER_DIR" "$DOC_DIR"

export WINEPREFIX="${WINEPREFIX:-/home/kasm-user/.wine}"
export WINEARCH="${WINEARCH:-win64}"

# Initialise the prefix if this is the first launch in the persistent profile.
wineboot -u >/tmp/grandma-wineboot.log 2>&1 || true

if [[ -n "$APP_EXE" && -f "$APP_EXE" ]]; then
  cd "$(dirname "$APP_EXE")"
  exec wine "$APP_EXE"
fi

# Try common installed locations before falling back to installer folder.
mapfile -t candidates < <(find "$WINEPREFIX/drive_c/Program Files" "$WINEPREFIX/drive_c/Program Files (x86)" -iname '*grandMA*onPC*.exe' -o -iname '*gma*onpc*.exe' 2>/dev/null | sort || true)
if (( ${#candidates[@]} > 0 )); then
  exec wine "${candidates[0]}"
fi

mapfile -t installers < <(find "$INSTALLER_DIR" -maxdepth 2 -type f \( -iname '*.exe' -o -iname '*.msi' \) | sort || true)
if (( ${#installers[@]} > 0 )); then
  exec wine "${installers[0]}"
fi

cat > "$DOC_DIR/README-${APP_FLAVOUR}.txt" <<EOF
${APP_FLAVOUR} Wine Kasm workspace

This is a Kasm 1.19 Wine container, not a Windows streaming tile.

To complete the app install, place the official MA Lighting ${APP_FLAVOUR} onPC installer in:
  ${INSTALLER_DIR}

Then relaunch the workspace. The launcher will run the installer/app inside the persistent Wine prefix:
  ${WINEPREFIX}

Host networking is enabled in the workspace config for MA-Net/Art-Net/sACN discovery.
EOF

zenity --info --title="${APP_FLAVOUR} Wine workspace" --width=520 --height=220 --text="${APP_FLAVOUR} is configured as a Wine container. Put the official installer in ${INSTALLER_DIR}, then relaunch this workspace." >/dev/null 2>&1 || true
exec xterm -title "${APP_FLAVOUR} Wine workspace" -e "cat '$DOC_DIR/README-${APP_FLAVOUR}.txt'; echo; read -p 'Press Enter to close...'"
