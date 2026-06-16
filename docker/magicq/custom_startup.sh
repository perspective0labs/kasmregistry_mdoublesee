#!/bin/bash
# MagicQ persistent storage setup for Kasm Workspaces
#
# Kasm injects KASM_PROFILE_PATH pointing at the user's persistent volume.
# We keep shows there so they survive container restarts.

MQDIR="/home/kasm-user/MagicQ"
PERSISTENT_SHOWS="${KASM_PROFILE_PATH:-/mnt/kasm_profiles}/magicq/shows"

mkdir -p "${MQDIR}"/{heads,log,personalities,fx,icons}
mkdir -p "${PERSISTENT_SHOWS}"

# Migrate any locally-written shows dir to the persistent volume on first run
if [ -d "${MQDIR}/shows" ] && [ ! -L "${MQDIR}/shows" ]; then
    cp -rn "${MQDIR}/shows/." "${PERSISTENT_SHOWS}/" 2>/dev/null || true
    rm -rf "${MQDIR}/shows"
fi

# Symlink shows → persistent volume
ln -sfn "${PERSISTENT_SHOWS}" "${MQDIR}/shows"

# Seed heads/personalities from image's first-launch expanded data
SRC="/opt/magicq/user"
if [ -d "$SRC" ] && [ "$(ls -A $SRC 2>/dev/null)" ]; then
    cp -rn "${SRC}/." "${MQDIR}/" 2>/dev/null || true
fi

chown -R 1000:1000 "${MQDIR}" 2>/dev/null || true
chown -R 1000:1000 "${PERSISTENT_SHOWS}" 2>/dev/null || true

echo "[MagicQ] Shows path: ${PERSISTENT_SHOWS} (persistent)"
