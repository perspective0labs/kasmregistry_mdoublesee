FROM kasmweb/core-ubuntu-focal:1.16.0

USER root

ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/magicq

# ── Runtime deps ─────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        libglu1-mesa \
        libgl1-mesa-glx \
        libxcb-xinerama0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-xfixes0 \
        libxkbcommon-x11-0 \
        libdbus-1-3 \
        libfontconfig1 \
        libfreetype6 \
        libasound2 \
        libudev1 \
        libusb-1.0-0 \
        libftdi1-2 \
        liblzo2-2 \
        xvfb \
        x11-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Install MagicQ ───────────────────────────────────────────────────────────
COPY magicq_linux_amd64.deb /tmp/magicq.deb
RUN dpkg -i /tmp/magicq.deb; apt-get install -f -y; dpkg -i /tmp/magicq.deb \
    && rm /tmp/magicq.deb

# ── First-launch under Xvfb: expands heads/personality library ───────────────
# MagicQ writes its user data to /opt/magicq/user on first run.
# 45 seconds is enough for full library initialisation.
RUN Xvfb :99 -screen 0 1280x1024x24 -ac & \
    sleep 2 && \
    DISPLAY=:99 \
    LD_LIBRARY_PATH=/opt/magicq/lib \
    QT_PLUGIN_PATH=/opt/magicq/plugins \
    QT_QPA_FONTDIR=/opt/magicq/lib/fonts \
    QT_AUTO_SCREEN_SCALE_FACTOR=0 \
    /opt/magicq/bin/mqqt -q & \
    MQ_PID=$! && \
    sleep 45 && \
    kill $MQ_PID 2>/dev/null || true && \
    pkill Xvfb 2>/dev/null || true && \
    echo "=== Expanded library contents ===" && \
    ls -lah /opt/magicq/user/ 2>/dev/null || true

# ── Desktop launcher ─────────────────────────────────────────────────────────
RUN mkdir -p $HOME/Desktop
COPY magicq.desktop $HOME/Desktop/magicq.desktop
RUN chmod +x $HOME/Desktop/magicq.desktop \
    && chown 1000:1000 $HOME/Desktop/magicq.desktop

# ── Per-session startup: symlink shows → persistent volume ───────────────────
COPY custom_startup.sh $STARTUPDIR/custom_startup.sh
RUN chmod +x $STARTUPDIR/custom_startup.sh

# ── Seed default profile from first-launch expanded data ─────────────────────
RUN mkdir -p /home/kasm-default-profile/MagicQ/{shows,heads,log,personalities,fx,icons} \
    && chown -R 1000:1000 /home/kasm-default-profile \
    && chown -R 1000:1000 /opt/magicq/user 2>/dev/null || true

ENV KASM_DISPLAY_RESOLUTION=1920x1080 \
    VNC_RESOLUTION=1920x1080 \
    KASM_PROFILE_PATH=/mnt/kasm_profiles

USER 1000
