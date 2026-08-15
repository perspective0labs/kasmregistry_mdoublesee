FROM kasmweb/kasmos-desktop:1.19.0-rolling-weekly

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    TOUCHDESIGNER_STREAM_HOST= \
    TOUCHDESIGNER_STREAM_PORT=3389 \
    TOUCHDESIGNER_STREAM_USER= \
    TOUCHDESIGNER_STREAM_MODE=rdp

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       freerdp2-x11 remmina remmina-plugin-rdp remmina-plugin-vnc \
       xdg-utils zenity curl ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY start-touchdesigner-stream.sh /usr/local/bin/start-touchdesigner-stream.sh
RUN chmod +x /usr/local/bin/start-touchdesigner-stream.sh \
    && mkdir -p /home/kasm-user/Documents/TouchDesigner /home/kasm-user/.config/remmina \
    && chown -R 1000:1000 /home/kasm-user/Documents/TouchDesigner /home/kasm-user/.config/remmina

USER 1000
CMD ["/dockerstartup/kasm_default_profile.sh"]
