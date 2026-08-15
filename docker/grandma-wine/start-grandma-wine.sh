#!/usr/bin/env bash
# grandMA onPC Wine launcher for Kasm workspaces.
#
# Order of operations:
#   1. Ensure the persistent Wine prefix exists and is initialised.
#   2. If the app is already installed, launch it.
#   3. Otherwise, if an official MA Lighting installer is present in the
#      installer volume, run it (silently where the installer supports it),
#      then launch the resulting binary.
#   4. Otherwise, show the operator clear instructions instead of dying.
#
# Nothing here downloads MA Lighting software — the installers are licensed and
# must be supplied by the operator via the persistent installer volume.
set -uo pipefail

APP_FLAVOUR="${GRANDMA_FLAVOUR:-grandMA onPC}"
APP_VERSION="${GRANDMA_VERSION:-unpinned}"
APP_EXE="${GRANDMA_EXE:-}"
INSTALLER_DIR="${GRANDMA_INSTALLER_DIR:-/home/kasm-user/grandma-installers}"
DOC_DIR="/home/kasm-user/Documents/grandMA"
LOG="/tmp/grandma-wine.log"

export WINEPREFIX="${WINEPREFIX:-/home/kasm-user/.wine}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDEBUG="${WINEDEBUG:--all}"

mkdir -p "$INSTALLER_DIR" "$DOC_DIR"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$LOG" >&2; }

log "Starting ${APP_FLAVOUR} (${APP_VERSION}) — prefix ${WINEPREFIX}"

# 1. Initialise/upgrade the prefix. Persistent volume means this is a no-op
#    after the first launch.
wineboot -u >>"$LOG" 2>&1 || log "wineboot returned non-zero (continuing)"
wineserver -w 2>/dev/null || true

find_installed() {
  find \
    "$WINEPREFIX/drive_c/Program Files" \
    "$WINEPREFIX/drive_c/Program Files (x86)" \
    -maxdepth 6 -type f \
    \( -iname 'grandMA*onPC*.exe' -o -iname 'gma*onpc*.exe' \) \
    2>/dev/null | sort | head -1
}

launch() {
  local exe="$1"
  log "Launching: $exe"
  cd "$(dirname "$exe")" || exit 1
  exec wine "$exe"
}

# 2. Explicit path from workspace.json wins.
if [[ -n "$APP_EXE" && -f "$APP_EXE" ]]; then
  launch "$APP_EXE"
fi

# 3. Otherwise scan the prefix for an existing install.
installed="$(find_installed)"
if [[ -n "$installed" ]]; then
  launch "$installed"
fi

# 4. Not installed yet — try the operator-supplied installer.
mapfile -t installers < <(
  find "$INSTALLER_DIR" -maxdepth 3 -type f \
    \( -iname '*.exe' -o -iname '*.msi' -o -iname '*.zip' \) 2>/dev/null | sort
)

if (( ${#installers[@]} > 0 )); then
  candidate="${installers[0]}"
  log "Found installer: $candidate"

  # MA3 ships onPC for Windows as a .zip containing the installer.
  if [[ "$candidate" == *.zip ]]; then
    workdir="$(mktemp -d)"
    log "Extracting $candidate -> $workdir"
    unzip -oq "$candidate" -d "$workdir" >>"$LOG" 2>&1 || log "unzip failed"
    extracted="$(find "$workdir" -type f -iname '*.exe' | sort | head -1)"
    [[ -n "$extracted" ]] && candidate="$extracted"
    log "Using extracted installer: $candidate"
  fi

  if [[ "$candidate" == *.msi ]]; then
    log "Running MSI installer"
    wine msiexec /i "$candidate" /qb >>"$LOG" 2>&1 || log "msiexec returned non-zero"
  else
    # MA installers are InnoSetup-family; /SILENT is honoured, but fall back to
    # an interactive run so the operator can complete it by hand if not.
    log "Running installer (attempting silent mode)"
    if ! wine "$candidate" /SILENT /SUPPRESSMSGBOXES /NORESTART >>"$LOG" 2>&1; then
      log "Silent install failed — running installer interactively"
      wine "$candidate" >>"$LOG" 2>&1 || log "interactive installer returned non-zero"
    fi
  fi

  wineserver -w 2>/dev/null || true

  installed="$(find_installed)"
  if [[ -n "$installed" ]]; then
    launch "$installed"
  fi
  log "Installer ran but no ${APP_FLAVOUR} binary was found in the prefix"
fi

# 5. Nothing to launch — leave the operator a readable desktop instead of a
#    container that exits immediately.
cat > "$DOC_DIR/README-${APP_FLAVOUR}.txt" <<EOF
${APP_FLAVOUR} — Kasm Wine workspace
Image target version: ${APP_VERSION}

This is a Kasm Wine container, not a Windows streaming tile.

MA Lighting software is licensed and is NOT bundled in this image.

To finish setup:
  1. Download the official installer from https://www.malighting.com/downloads/
       grandMA2 onPC : gMA2onPC_v<version>.exe
       grandMA3 onPC : grandMA3_onPC_win_v<version>.zip
  2. Copy it into this persistent folder:
       ${INSTALLER_DIR}
  3. Relaunch this workspace.

The launcher will install it into the persistent Wine prefix:
  ${WINEPREFIX}

and start it automatically on every subsequent launch.

Networking: the workspace runs with host networking so MA-Net, Art-Net (UDP 8000)
and sACN (UDP 5568) discovery reaches the physical rig.

Launcher log: ${LOG}
EOF

zenity --info --title="${APP_FLAVOUR} Wine workspace" --width=560 --height=240 \
  --text="${APP_FLAVOUR} is not installed yet.\n\nPut the official MA Lighting installer in:\n${INSTALLER_DIR}\n\nThen relaunch this workspace." \
  >/dev/null 2>&1 || true

exec xterm -title "${APP_FLAVOUR} Wine workspace" \
  -e "cat '$DOC_DIR/README-${APP_FLAVOUR}.txt'; echo; read -p 'Press Enter to close...'"
