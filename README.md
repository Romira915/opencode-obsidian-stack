# opencode-obsidian-stack

Docker Compose stack for using OpenChamber as the OpenCode web UI while syncing an Obsidian vault through Self-hosted LiveSync CLI.

## Components

- `openchamber`: OpenChamber web UI. It manages/uses OpenCode and exposes the browser UI on port `3000` by default.
- `livesync-cli`: Headless Self-hosted LiveSync CLI daemon. It watches the mounted vault and syncs changes with the existing LiveSync CouchDB.
- `VAULT_PATH`: Host-side Obsidian vault path mounted into both containers.

## Setup

The files in this repository are deployment configuration. Local persistent data is kept under `./data/` and ignored by git.

1. Create `.env`.

```bash
cp .env.example .env
```

2. Edit `.env`.

```env
OPENCHAMBER_PORT=3000
UI_PASSWORD=long-random-password
VAULT_PATH=./data/vault
OPENCHAMBER_REF=main
LIVESYNC_REF=0.25.76-cli
```

For local single-host operation, `VAULT_PATH=./data/vault` is recommended. The whole `data/` directory is ignored by git.

3. Prepare OpenChamber data directories.

```bash
mkdir -p data/openchamber data/opencode/share data/opencode/state data/opencode/config data/ssh data/vault
chown -R 1000:1000 data
```

These directories live on the deployment host:

```text
data/openchamber    OpenChamber config
data/opencode/share OpenCode share data
data/opencode/state OpenCode state data
data/opencode/config OpenCode config
data/ssh            SSH config/keys visible as /home/openchamber/.ssh in the container
data/vault          Obsidian vault synced by LiveSync CLI
```

4. Configure LiveSync CLI once.

Use your existing Obsidian LiveSync setup URI and setup passphrase. This writes `.livesync/settings.json` under the mounted vault.

Do not paste secrets directly into shell commands. Use the helper script so the values are read interactively and are not saved in shell history.

```bash
docker compose build --no-cache livesync-cli
bash scripts/setup-livesync.sh
```

If the stack is started before this setup, `livesync-cli` stays idle instead of restart-looping.

5. Start the stack.

```bash
docker compose up -d
```

OpenChamber will be available at `http://localhost:3000` unless `OPENCHAMBER_PORT` is changed.

## Vault Layout

OpenChamber sees the vault as:

```text
/home/openchamber/workspaces/obsidian-vault
```

LiveSync CLI sees the same host directory as:

```text
/vault
```

## Notes

- Keep Self-hosted LiveSync as the only sync mechanism for this vault.
- Do not add Syncthing, rsync loops, Dropbox, or other file sync tools to the same vault.
- Use `.livesync/ignore` inside the vault to exclude generated files that should not be synced.
- OpenChamber is built from `https://github.com/openchamber/openchamber` instead of relying on a third-party Docker Hub image.
- Self-hosted LiveSync CLI is built from `https://github.com/vrtmrz/obsidian-livesync`. `LIVESYNC_REF` defaults to a release tag so production builds do not unexpectedly follow upstream `main`.

## Troubleshooting

### LiveSync setup fails on first try

`docker compose build livesync-cli` may use stale build cache and skip applying the patch that prevents the exit handler from overwriting `settings.json`. Always build with `--no-cache` before setup:

```bash
docker compose build --no-cache livesync-cli
bash scripts/setup-livesync.sh
```

### LiveSync image build fails on runtime-package.json

Older versions of this stack copied `src/apps/cli/runtime-package.json` directly from the upstream repository. Some upstream refs provide that file, while newer refs keep the runtime dependency list in `src/apps/cli/package.json`. This stack normalizes either layout during the builder stage. Rebuild after pulling this stack update:

```bash
docker compose build --no-cache livesync-cli
```

### Synced files owned by root, OpenChamber can't read

`livesync-cli` container runs as root by default. `compose.yml` sets `user: "${HOST_UID:-1000}:${HOST_GID:-1000}"` to match `openchamber`. After first sync or after this config change:

```bash
sudo chown -R "${HOST_UID:-1000}:${HOST_GID:-1000}" data/vault
docker compose up -d livesync-cli
```

### File tree not showing in browser

Browser cache / Service Worker can cause stale file tree. Try:
- Incognito / private window
- Another browser
- DevTools → Disable cache + hard reload

### Reverse proxy drops live updates

OpenChamber uses long-lived event streams and WebSocket connections. If session titles, status, or permission prompts do not update through nginx, disable buffering and forward upgrade headers:

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    server_name opencode.example.com;

    proxy_buffering off;
    client_max_body_size 100m;

    location / {
        proxy_pass http://127.0.0.1:4180;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

## OpenChamber Desktop

OpenChamber Desktop (1.13.9+) can connect to this stack without going through the Google OAuth flow in a browser. A small nginx sidecar (`desktop-bypass-nginx`) listens on `127.0.0.1:4181` and forwards requests with a matching `X-Desktop-Token` header directly to openchamber, skipping oauth2-proxy.

### Setup

1. After running `bash scripts/setup.sh`, a shared secret is generated at `data/desktop-bypass-token/token` (chmod 600). The container reads this on every start.

2. Make the sidecar reachable from the host running the front-door nginx. The sidecar is already published on `127.0.0.1:4181` by compose. Point the front-door nginx (e.g. `/etc/nginx/sites-available/opencode.romira.dev.conf`) at it:

   ```nginx
   location / {
       proxy_pass http://127.0.0.1:4181;  # was: http://127.0.0.1:4180 (oauth2-proxy)
       ...
   }
   ```

3. In OpenChamber Desktop, add a remote host with these settings:
   - **URL**: `https://opencode.romira.dev`
   - **Custom Request Headers**: Key `X-Desktop-Token`, Value = contents of `data/desktop-bypass-token/token`

4. On first connection, the openchamber password prompt appears. Enter `UI_PASSWORD` from `.env`. The client token is stored in Desktop and re-used until it expires.

### Browser access (unchanged)

The browser flow still goes through oauth2-proxy + Google OAuth. Only Desktop requests carrying the matching `X-Desktop-Token` skip oauth2-proxy. The `X-Desktop-Token` header is consumed by the sidecar and never reaches openchamber.

### Rotating the shared secret

```bash
openssl rand -base64 32 > data/desktop-bypass-token/token
chmod 600 data/desktop-bypass-token/token
docker compose up -d desktop-bypass-nginx
```

Then update the `X-Desktop-Token` value in OpenChamber Desktop.

## References

- OpenChamber: https://github.com/openchamber/openchamber
- Self-hosted LiveSync CLI: https://github.com/vrtmrz/obsidian-livesync/tree/main/src/apps/cli
