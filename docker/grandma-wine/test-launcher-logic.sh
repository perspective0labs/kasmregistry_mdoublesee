#!/usr/bin/env bash
# Offline unit test for the launcher's flavour-matching and installer-family
# detection. Exercises the same logic without Wine or a display.
set -uo pipefail
fail=0
check() { # name expected actual
  if [[ "$2" == "$3" ]]; then printf 'ok   %s\n' "$1"
  else printf 'FAIL %s: expected=%s actual=%s\n' "$1" "$2" "$3"; fail=1; fi
}

matches_flavour() { # gen file
  local MA_GEN="$1" base; base="$(basename "$2")"
  case "$base" in
    *_mac_*|*_macos_*|*_osx_*|*_linux_*|*.dmg|*.pkg|*.deb|*.rpm) return 1 ;;
  esac
  case "$MA_GEN" in
    3) [[ "$base" =~ ^([Gg]rand)?[Mm][Aa]3 || "$base" == *[Mm][Aa]3* ]] ;;
    2) [[ "$base" =~ ^([Gg]rand)?[Mm][Aa]2 || "$base" == *[Mm][Aa]2* ]] ;;
    *) return 0 ;;
  esac
}

m() { matches_flavour "$1" "$2" && echo yes || echo no; }

# Real official filenames.
MA2=gMA2onPC_v3.9.63.6.exe
MA3=grandMA3_onPC_win_v2.4.2.2.zip
MA3MAC=grandMA3_onPC_mac_v2.4.2.2.zip

check "MA2 ws accepts MA2 installer"  yes "$(m 2 $MA2)"
check "MA2 ws rejects MA3 installer"  no  "$(m 2 $MA3)"
check "MA3 ws accepts MA3 win zip"    yes "$(m 3 $MA3)"
check "MA3 ws rejects MA2 installer"  no  "$(m 3 $MA2)"
check "MA3 ws rejects MA3 MAC zip"    no  "$(m 3 $MA3MAC)"

# The original bug: sorted()[0] over a shared folder gave MA3 the MA2 installer.
picked=$(printf '%s\n%s\n' "$MA2" "$MA3" | sort -V | head -1)
check "old code would mispick for MA3" "$MA2" "$picked"

# Family detection against the real binaries when present.
detect() {
  local c="$1"
  sniff() {
    local head_bytes
    head_bytes="$(LC_ALL=C tr -d '\0' < "$1" 2>/dev/null | LC_ALL=C head -c 3000000)"
    [[ "$head_bytes" == *"$2"* ]]
  }
  if [[ "$c" == *.msi ]]; then echo msi
  elif sniff "$c" 'Nullsoft'; then echo nsis
  elif sniff "$c" 'Inno Setup'; then echo inno
  else echo unknown; fi
}
real2="$HOME/Downloads/$MA2"
if [[ -f "$real2" ]]; then
  check "MA2 installer family" nsis "$(detect "$real2")"
else
  echo "skip MA2 family (installer not present)"
fi

# Regression guard for the SIGPIPE/pipefail misdetection.
badsniff() { head -c 3000000 "$1" 2>/dev/null | grep -qa 'Nullsoft'; }
if [[ -f "$real2" ]]; then
  ( set -uo pipefail; badsniff "$real2" ) ; rc=$?
  if (( rc == 0 )); then
    echo "note: pipe form happened to work here (rc=0)"
  else
    printf 'ok   pipe form is broken under pipefail as expected (rc=%s) — new sniff avoids it\n' "$rc"
  fi
fi

exit $fail
