"""
kasm-setup-trigger: lightweight HTTP server that ensures OpenClaw/Hermes/LiteLLM
are running in WSL2 Docker. Called by Kasm workspace exec_config on launch.
"""
import subprocess
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

DATA_DIR = os.environ.get("DATA_DIR", "/data")

SERVICES = {
    "openclaw": [
        {
            "name": "openclaw",
            "image": "ghcr.io/openclaw/openclaw:latest",
            "volumes": [f"{DATA_DIR}/openclaw:/home/node/.openclaw"],
            "env_file": f"{DATA_DIR}/openclaw/.env",
            "restart": "unless-stopped",
            "network": "bridge",
        }
    ],
    "hermes": [
        {
            "name": "hermes",
            "image": "ghcr.io/perspective0labs/hermes-agent-dashboard:latest",
            "volumes": [f"{DATA_DIR}/hermes:/root/.hermes"],
            "env_file": f"{DATA_DIR}/hermes/.env",
            "environment": ["HERMES_DASHBOARD=false"],
            "restart": "unless-stopped",
        },
        {
            "name": "hermes-dashboard",
            "image": "ghcr.io/perspective0labs/hermes-agent-dashboard:latest",
            "volumes": [f"{DATA_DIR}/hermes:/root/.hermes"],
            "env_file": f"{DATA_DIR}/hermes/.env",
            "restart": "unless-stopped",
            "ports": ["9119:9119"],
            "entrypoint": ["/opt/hermes/.venv/bin/hermes", "dashboard", "--port", "9119"],
        },
    ],
    "litellm": [
        {
            "name": "litellm",
            "image": "litellm/litellm:v1.88.2",
            "volumes": [f"{DATA_DIR}/litellm:/app/config"],
            "restart": "unless-stopped",
            "ports": ["4000:4000"],
            "cmd": ["--config", "/app/config/config.yaml", "--port", "4000"],
        }
    ],
}


def _docker(*args, check=False):
    return subprocess.run(["docker"] + list(args), capture_output=True, text=True, check=check)


def container_running(name):
    r = _docker("inspect", "--format", "{{.State.Running}}", name)
    return r.stdout.strip() == "true"


def container_exists(name):
    return _docker("inspect", "--format", "{{.Name}}", name).returncode == 0


def ensure_service(cfg):
    name = cfg["name"]

    if container_running(name):
        return f"{name}: already running"

    if container_exists(name):
        _docker("start", name)
        return f"{name}: started (was stopped)"

    # Build docker run command
    cmd = ["run", "-d", f"--name={name}", f"--restart={cfg.get('restart', 'unless-stopped')}"]

    for v in cfg.get("volumes", []):
        cmd += ["-v", v]

    env_file = cfg.get("env_file")
    if env_file and os.path.exists(env_file):
        cmd += ["--env-file", env_file]

    for e in cfg.get("environment", []):
        cmd += ["-e", e]

    for p in cfg.get("ports", []):
        cmd += ["-p", p]

    net = cfg.get("network")
    if net:
        cmd += [f"--network={net}"]

    entrypoint = cfg.get("entrypoint")
    if entrypoint:
        cmd += ["--entrypoint", entrypoint[0]]

    cmd.append(cfg["image"])

    if entrypoint and len(entrypoint) > 1:
        cmd += entrypoint[1:]
    elif cfg.get("cmd"):
        cmd += cfg["cmd"]

    r = _docker(*cmd)
    if r.returncode != 0:
        return f"{name}: FAILED — {r.stderr.strip()}"
    return f"{name}: installed and started"


def ensure_all(service_key):
    cfgs = SERVICES.get(service_key, [])
    if not cfgs:
        return f"unknown service: {service_key}"
    return "\n".join(ensure_service(c) for c in cfgs)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.lstrip("/")

        if path == "health":
            self._respond(200, "ok")
            return

        if path.startswith("ensure-"):
            key = path[len("ensure-"):]
            msg = ensure_all(key)
            print(msg)
            self._respond(200, msg)
            return

        self._respond(404, "not found")

    def _respond(self, code, body):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 19500))
    print(f"kasm-setup-trigger listening on :{port}")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()
