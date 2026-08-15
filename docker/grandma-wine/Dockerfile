FROM kasmweb/kasmos-desktop:1.19.0-rolling-weekly

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    WINEPREFIX=/home/kasm-user/.wine \
    WINEARCH=win64

RUN apt-get update && \
    apt-get install -y --no-install-recommends wine64 winbind cabextract p7zip-full zenity xterm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start-grandma-wine.sh /usr/local/bin/start-grandma-wine.sh
RUN chmod +x /usr/local/bin/start-grandma-wine.sh && \
    ln -sf /usr/lib/wine/wine64 /usr/local/bin/wine && \
    ln -sf /usr/lib/wine/wineserver64 /usr/local/bin/wineserver && \
    mkdir -p /home/kasm-user/grandma-installers /home/kasm-user/Documents/grandMA && \
    chown -R 1000:1000 /home/kasm-user/grandma-installers /home/kasm-user/Documents/grandMA

USER 1000
CMD ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
