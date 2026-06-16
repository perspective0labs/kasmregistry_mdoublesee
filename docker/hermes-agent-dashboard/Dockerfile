FROM nousresearch/hermes-agent:latest

# Install Node.js 20 LTS and git
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl git ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone, install and build the Kori-x hermes-dashboard
RUN git clone --depth=1 https://github.com/Kori-x/hermes-dashboard.git /opt/hermes-dashboard && \
    cd /opt/hermes-dashboard && \
    npm ci --prefer-offline && \
    HERMES_HOME=/opt/data ./install.sh

# Register kori-dashboard as an s6-overlay v3 longrun service
RUN mkdir -p /etc/s6-overlay/s6-rc.d/kori-dashboard/dependencies.d && \
    echo longrun > /etc/s6-overlay/s6-rc.d/kori-dashboard/type && \
    echo base > /etc/s6-overlay/s6-rc.d/kori-dashboard/dependencies.d/base && \
    mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d && \
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/kori-dashboard

COPY kori-dashboard-run /etc/s6-overlay/s6-rc.d/kori-dashboard/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/kori-dashboard/run

# hermes ports: 8642 (API), 9119 (built-in dashboard)
# kori-dashboard ports: 5173 (UI), 3001 (WebSocket), 3002 (wiki API)
EXPOSE 8642 9119 5173 3001 3002
