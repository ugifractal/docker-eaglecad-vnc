# eagle-docker — EAGLE CAD 7.7.0 via VNC

Runs legacy EAGLE CAD 7.7.0 (needs libssl1.0.0) in Ubuntu 20.04 + XFCE + TigerVNC, so it works on modern hosts.

## Prerequisites
- Docker with `linux/amd64` support (Apple Silicon uses emulation)
- A VNC client (TigerVNC Viewer / RealVNC Viewer)
- Your own licensed copy of the EAGLE 7.7.0 Linux installer,
  placed in this directory as `eagle-lin64-7.7.0.run`
  (proprietary CadSoft software — not included in the repo).
  The build fails without it (`test -x` guard in the Dockerfile).

## Get the source
```sh
git clone https://github.com/ugifractal/docker-eaglecad-vnc
cd docker-eaglecad-vnc
```

## Quickstart
1. Set the data path in `.env.docker`: `DOCKER_DATA_PATH=<host dir>` (projects live in `<host dir>/eagle`)
2. Build + run: `docker compose --env-file .env.docker up --build -d`
3. Connect VNC to `localhost:5901`, password `password`
4. Launch EAGLE: double-click **EAGLE 7.7.0** on the desktop, or run `eagle &` in Xfce Terminal
5. Open your project under `/root/projects` (mounted from host)

## Notes
- Screen size is `1280x800` (set in `Dockerfile CMD`).
- Port `6080` is mapped in compose but not served — use a VNC client on `5901`.
- See `AGENTS.md` for maintainer notes (installer quirks, VNC defaults).
