# grandMA onPC Wine workspace for Kasm
#
# One image definition serves both grandMA2 onPC and grandMA3 onPC. The MA
# Lighting installers are NOT baked in (licensing) — the launcher installs from
# the persistent installer volume on first run, then reuses the Wine prefix.
#
# Build args let the workflow pin the Kasm base and record which MA version the
# image was cut for.
ARG KASM_BASE=kasmweb/kasmos-desktop:1.19.0-rolling-weekly
FROM ${KASM_BASE}

ARG GRANDMA_FLAVOUR="grandMA onPC"
ARG GRANDMA_VERSION="unpinned"
ARG WINE_BRANCH=stable

LABEL org.opencontainers.image.title="${GRANDMA_FLAVOUR} (Kasm Wine)" \
      org.opencontainers.image.description="MA Lighting ${GRANDMA_FLAVOUR} running under Wine in a Kasm desktop container." \
      org.opencontainers.image.source="https://github.com/perspective0labs/kasmregistry_mdoublesee" \
      org.opencontainers.image.vendor="perspective0labs" \
      io.perspective0labs.grandma.flavour="${GRANDMA_FLAVOUR}" \
      io.perspective0labs.grandma.version="${GRANDMA_VERSION}"

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    WINEPREFIX=/home/kasm-user/.wine \
    WINEARCH=win64 \
    WINEDLLOVERRIDES=mscoree=d \
    GRANDMA_FLAVOUR="${GRANDMA_FLAVOUR}" \
    GRANDMA_VERSION="${GRANDMA_VERSION}"

# WineHQ stable rather than the distro wine package: the Kasm base tracks
# Debian bookworm, whose `wine` is old, and Ubuntu noble dropped the `wine64`
# binary package name entirely. Detect the distro (debian vs ubuntu) from
# /etc/os-release so this works whichever base Kasm ships.
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg; \
    mkdir -pm755 /etc/apt/keyrings; \
    wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key; \
    . /etc/os-release; \
    case "${ID}" in \
      ubuntu) WINE_DISTRO=ubuntu ;; \
      debian) WINE_DISTRO=debian ;; \
      *)      WINE_DISTRO="${ID_LIKE%% *}" ;; \
    esac; \
    echo "WineHQ repo: ${WINE_DISTRO}/${VERSION_CODENAME}"; \
    wget -qO /etc/apt/sources.list.d/winehq.sources \
      "https://dl.winehq.org/wine-builds/${WINE_DISTRO}/dists/${VERSION_CODENAME}/winehq-${VERSION_CODENAME}.sources"; \
    apt-get update; \
    apt-get install -y --no-install-recommends "winehq-${WINE_BRANCH}" \
      winbind cabextract p7zip-full zenity xterm unzip curl procps; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY start-grandma-wine.sh /usr/local/bin/start-grandma-wine.sh
RUN set -eux; \
    chmod +x /usr/local/bin/start-grandma-wine.sh; \
    mkdir -p /home/kasm-user/grandma-installers /home/kasm-user/Documents/grandMA; \
    chown -R 1000:1000 /home/kasm-user/grandma-installers /home/kasm-user/Documents/grandMA; \
    command -v wine; \
    wine --version

USER 1000
CMD ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
