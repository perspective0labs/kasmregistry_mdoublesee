#!/usr/bin/env bash
# grandMA onPC Wine launcher for Kasm workspaces.
#
# Order of operations:
#   1. Ensure the persistent Wine prefix exists and is initialised.
#   2. If the app is already installed, launch it.
#   3. Otherwise, if an official MA Lighting installer matching THIS flavour is
#      present in the installer volume, run it silently, then launch the result.
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

# Which MA generation is this workspace? Drives installer matching and the
# install-scan pattern so a shared installer folder can hold both MA2 and MA3
# without either workspace picking up the wrong product.
case "$APP_FLAVOUR" in
  *3*) MA_GEN=3 ;;
  *2*) MA_GEN=2 ;;
  *)   MA_GEN=0 ;;
esac

export WINEPREFIX="${WINEPREFIX:-/home/kasm-user/.wine}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDEBUG="${WINEDEBUG:--all}"
# Under `bash -lc` from Kasm's exec_config the login shell may not inherit the
# session DISPLAY; wineboot and the installers both need an X display.
export DISPLAY="${DISPLAY:-:1}"

mkdir -p "$INSTALLER_DIR" "$DOC_DIR"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "$LOG" >&2; }

log "Starting ${APP_FLAVOUR} (${APP_VERSION}) — prefix ${WINEPREFIX} — display ${DISPLAY}"

# 1. Initialise/upgrade the prefix. Persistent volume means this is a no-op
#    after the first launch.
wineboot -u >>"$LOG" 2>&1 || log "wineboot returned non-zero (continuing)"
wineserver -w 2>/dev/null || true

find_installed() {
  # MA2 installs its binary as gma2_onPC.exe (not "grandMA2 onPC.exe"), so the
  # scan must cover both the gma2/gma3 and grandMA2/grandMA3 spellings. Keep the
  # generation in the pattern so a shared prefix can't cross-launch.
  local -a pats
  case "$MA_GEN" in
    3) pats=('grandMA3*onPC*.exe' 'gma3*onpc*.exe') ;;
    2) pats=('grandMA2*onPC*.exe' 'gma2*onpc*.exe') ;;
    *) pats=('grandMA*onPC*.exe'  'gma*onpc*.exe')  ;;
  esac
  find \
    "$WINEPREFIX/drive_c/Program Files" \
    "$WINEPREFIX/drive_c/Program Files (x86)" \
    -maxdepth 6 -type f \
    \( -iname "${pats[0]}" -o -iname "${pats[1]}" \) \
    2>/dev/null | sort -V | tail -1
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

# 4. Not installed yet — find an operator-supplied installer FOR THIS FLAVOUR.
#    The installer volume is shared between the MA2 and MA3 workspaces, so an
#    unfiltered pick would let the MA3 workspace install MA2 (gMA2onPC_* sorts
#    first). Match on the MA generation instead.
#    Official filenames:
#      MA2 : gMA2onPC_v<version>.exe
#      MA3 : grandMA3_onPC_win_v<version>.zip  (contains ma/<same>.exe)
matches_flavour() {
  local base; base="$(basename "$1")"
  # Exclude non-Windows builds. MA Lighting publishes macOS and Linux onPC
  # packages with the same grandMA3_onPC_* prefix (e.g.
  # grandMA3_onPC_mac_v2.4.2.2.zip); those contain no Windows .exe and cannot
  # run under Wine, but they DO match the generation test below.
  case "$base" in
    *_mac_*|*_macos_*|*_osx_*|*_linux_*|*.dmg|*.pkg|*.deb|*.rpm)
      return 1 ;;
  esac
  case "$MA_GEN" in
    3) [[ "$base" =~ ^([Gg]rand)?[Mm][Aa]3 || "$base" == *[Mm][Aa]3* ]] ;;
    2) [[ "$base" =~ ^([Gg]rand)?[Mm][Aa]2 || "$base" == *[Mm][Aa]2* ]] ;;
    *) return 0 ;;
  esac
}

mapfile -t all_installers < <(
  find "$INSTALLER_DIR" -maxdepth 3 -type f \
    \( -iname '*.exe' -o -iname '*.msi' -o -iname '*.zip' \) 2>/dev/null | sort -V
)

installers=()
for f in "${all_installers[@]:-}"; do
  [[ -n "$f" ]] || continue
  if matches_flavour "$f"; then
    installers+=("$f")
  else
    log "Ignoring installer for a different MA generation: $(basename "$f")"
  fi
done

if (( ${#installers[@]} > 0 )); then
  # Highest version wins.
  candidate="${installers[-1]}"
  log "Found installer: $candidate"

  # MA3 ships onPC for Windows as a .zip containing ma/<installer>.exe.
  if [[ "$candidate" == *.zip ]]; then
    workdir="$(mktemp -d)"
    log "Extracting $candidate -> $workdir"
    unzip -oq "$candidate" -d "$workdir" >>"$LOG" 2>&1 || log "unzip failed"
    extracted="$(find "$workdir" -type f -iname '*.exe' 2>/dev/null | sort -V | tail -1)"
    if [[ -n "$extracted" ]]; then
      candidate="$extracted"
      log "Using extracted installer: $candidate"
    else
      log "No .exe found inside $candidate"
    fi
  fi

  # Identify the installer family rather than guessing. Both current MA2 and
  # MA3 onPC installers are NSIS, whose silent switch is a bare `/S` — the
  # InnoSetup switches (/SILENT /SUPPRESSMSGBOXES) are NOT recognised by NSIS
  # and leave the installer sitting on an interactive GUI (or exiting without
  # installing), which is why the app never appeared in the prefix.
  # NOTE: do NOT implement this as `head -c N file | grep -q`. Under
  # `set -o pipefail`, grep -q exits as soon as it matches, head takes SIGPIPE,
  # and the pipeline reports 141 *even though the pattern matched* — which
  # silently misdetects every installer as "unknown". Read into a variable and
  # match in-shell instead of piping.
  sniff() { # file pattern -> 0 if pattern occurs in the first 3MB
    local head_bytes
    head_bytes="$(LC_ALL=C tr -d '\0' < "$1" 2>/dev/null | LC_ALL=C head -c 3000000)"
    [[ "$head_bytes" == *"$2"* ]]
  }

  installer_kind="unknown"
  if [[ "$candidate" == *.msi ]]; then
    installer_kind="msi"
  elif sniff "$candidate" 'Nullsoft'; then
    installer_kind="nsis"
  elif sniff "$candidate" 'Inno Setup'; then
    installer_kind="inno"
  fi
  log "Installer family detected: ${installer_kind}"

  run_installer() {
    log "Install attempt: wine $(basename "$candidate") $*"
    wine "$candidate" "$@" >>"$LOG" 2>&1
    local rc=$?
    wineserver -w 2>/dev/null || true
    log "Installer exited rc=${rc}"
    [[ -n "$(find_installed)" ]]
  }

  installed_ok=false
  case "$installer_kind" in
    msi)
      run_installer /i "$candidate" /qb && installed_ok=true
      # msiexec takes the package as an argument, not the exe itself.
      if ! $installed_ok; then
        log "Running msiexec directly"
        wine msiexec /i "$candidate" /qb >>"$LOG" 2>&1 || log "msiexec returned non-zero"
        wineserver -w 2>/dev/null || true
        [[ -n "$(find_installed)" ]] && installed_ok=true
      fi
      ;;
    nsis)
      # NSIS: `/S` must be uppercase and is position-sensitive (first arg).
      run_installer /S && installed_ok=true
      ;;
    inno)
      run_installer /SILENT /SUPPRESSMSGBOXES /NORESTART && installed_ok=true
      ;;
    *)
      # Unknown family — try the NSIS switch first (matches current MA
      # installers), then InnoSetup.
      run_installer /S && installed_ok=true
      $installed_ok || { run_installer /SILENT /SUPPRESSMSGBOXES /NORESTART && installed_ok=true; }
      ;;
  esac

  # Last resort: let the operator drive the installer GUI by hand.
  if ! $installed_ok; then
    log "Silent install did not produce a binary — running installer interactively"
    run_installer && installed_ok=true
  fi

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

Note: the installer folder is shared between the MA2 and MA3 workspaces. This
launcher only picks up installers matching grandMA${MA_GEN}, so it is safe to
keep both in the same folder.

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
