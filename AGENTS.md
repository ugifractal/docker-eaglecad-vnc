# eagle-docker — EAGLE CAD 7.7.0 via VNC

Docker wrapper to run legacy EAGLE CAD 7.7.0 (needs libssl1.0.0) in Ubuntu 20.04 + XFCE + TigerVNC.

## Structure
- `Dockerfile` — only build definition. Do not bump `ubuntu:20.04` without replacing libssl1.0.0/1.1 manual installs.
- `compose.yml` — service `eaglecad` (`linux/amd64`), container `eagle7-vnc-container`.
- `.env.docker` — provides `DOCKER_DATA_PATH`. Required for volume mount.
- `eagle-lin64-7.7.0.run` — installer binary, must stay in build context (`COPY` in Dockerfile). Takes BASE dir as positional arg (`./eagle-lin64-7.7.0.run /opt` → `/opt/eagle-7.7.0`); any dash-flag only prints USAGE and exits 0, silently leaving `/opt` empty. Install step has `test -x` guard.

## Commands
- Build + run: `docker compose --env-file .env.docker up --build -d`
- Logs/shell: `docker logs eagle7-vnc-container`, `docker exec -it eagle7-vnc-container bash`
- Run EAGLE inside container: `eagle` (symlink to `/opt/eagle-7.7.0/bin/eagle`)
- Launch GUI apps headless: `docker exec -e DISPLAY=:1 eagle7-vnc-container <app> &`
- XFCE default terminal is pinned to `xfce4-terminal` via `helpers.rc` + `update-alternatives`; `xterm` is fallback. Do not default to `gnome-terminal` (needs D-Bus, which `xstartup` unsets).

## Env / Access
- Requires `DOCKER_DATA_PATH` (see `.env.docker`); host data at `$DOCKER_DATA_PATH/eagle` → `/root/projects`.
- VNC on `5901`, password `password` (hardcoded `Dockerfile:48`, rebuild to change).
- `6080` mapped in compose but NOT served — no noVNC/websockify in image. Use TigerVNC/RealVNC on 5901.

## Notes
- No tests, lint, CI.
- `EXPOSE 5901` only; VNC geometry `1280x800` set in `CMD`.
- `CMD` must end with a foreground process (`tail -F /root/.vnc/*.log`) — bare `vncserver :1` daemonizes, container exits 0 and restart-loops.
