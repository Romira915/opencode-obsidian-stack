# MEMORY

## 2026-05-30 OpenChamber session title investigation

### Completed
- Investigated why OpenChamber session titles stay as `New session` / `New session - ...`.
- Verified OpenCode backend title generation still exists and works on normal replies:
  - Created a test session through OpenChamber proxy.
  - Sent a normal `/message` request.
  - Title changed asynchronously from `New session - ...` to a generated Japanese title after `session.updated`.
- Confirmed `noReply:true` messages do not trigger title generation. Title generation runs only during normal prompt loop and only when there is exactly one real user message and the title is still the default.
- Found browser-side errors showing OpenChamber sync/API requests returning `401 Unauthorized`:
  - `/api/global/event`
  - `/api/global/event/ws`
  - `/api/session/status`
  - `/api/session/{id}`
  - `/api/question`, `/api/permission`
- Confirmed `/auth/session` can return `401 {"authenticated":false,"locked":true}` when OpenChamber UI auth is not valid.
- Confirmed `POST /auth/session` returns `200` and sets `oc_ui_session` with `HttpOnly; SameSite=Strict; Secure; Path=/; Max-Age=604800`.
- Connected to remote host `oci-tokyo-ampere` and checked production logs under `/home/openchamber/.local/share/opencode/log`.
- Root cause found: title generation was running, but hidden `title` agent used `opencode/gpt-5-nano`; opencode.ai returned `CreditsError` / `Insufficient balance`, so session titles stayed at the default.
- Added and pushed oauth2-proxy / reverse proxy improvements:
  - Commit `62e7165 fix: improve oauth2 proxy websocket support`
  - `compose.yml`: added `--pass-host-header=true` and `--proxy-websockets=true`.
  - `README.md`: documented nginx settings for long-lived SSE/WebSocket updates.
- Added and pushed nested config repo fix:
  - Repo: `romira-s-config`
  - Commit `ff6041b fix: use free model for opencode title agent`
  - `ai-config/opencode/opencode.json`: override hidden `title` agent model to `opencode/deepseek-v4-flash-free`.
- Pulled `romira-s-config` on `oci-tokyo-ampere` and restarted `openchamber` so OpenCode reloads config.
- `docker compose config --quiet` passed before commit.
- Fixed OpenChamber restart failure caused by the container environment not resolving the npm global `opencode` binary:
  - Commit `7eba915 fix: set opencode binary path in container`
  - `compose.yml`: added `OPENCODE_BINARY=/home/openchamber/.npm-global/bin/opencode`.
  - `compose.yml`: prepended `/home/openchamber/.npm-global/bin` to `PATH`.
- Pulled commit `7eba915` on `oci-tokyo-ampere`, recreated `openchamber`, and restarted `oauth2-proxy`.
- Verified `/health` returns `200 OK` and reports:
  - `openCodeRunning: true`
  - `isOpenCodeReady: true`
  - `opencodeBinarySource: "env"`
  - `opencodeLaunchBinary: "/home/openchamber/.npm-global/bin/opencode"`
- Verified fresh title generation after the fix:
  - New session `ses_189078dfcffepa5ou2ud71Ub4J` has title `Greeting`.
  - Latest log `/home/openchamber/.local/share/opencode/log/2026-05-30T033841.log` shows `agent=title` using `modelID=deepseek-v4-flash-free`.

### Current Status
- Branch `main` is pushed to `origin/main` at `7eba915`.
- Worktree still has an unrelated `.env.example` modification that was not touched or committed in this session.
- `MEMORY.md` is untracked unless committed later.
- Deployed config inside the container now includes `agent.title.model = opencode/deepseek-v4-flash-free`.
- Production OpenChamber is running with a single web server process and a managed OpenCode server process.

### Important Findings
- The issue was not nginx/oauth2-proxy/WebSocket after all. WS returned `101 Switching Protocols`, `/auth/session` returned `200`, and `session.updated` events arrived.
- The backend API for the problem session still returned `title: "New session - ..."`, proving title generation had failed server-side.
- Logs showed title agent failures from insufficient opencode.ai balance.
- If `/api/session/{id}` shows the generated title but UI remains stale, the problem is live sync/event stream delivery.
- If `/api/session/{id}` remains default title, the problem is title-generation trigger conditions or title agent failure for that session.

## 2026-06-07 Google Workspace MCP 認証永続化

### Completed
- `compose.yml`: `./data/google-workspace-mcp:/home/openchamber/.google_workspace_mcp` を volume mount に追加
- `scripts/setup-data-dirs.sh`: `$REPO_DIR/data/google-workspace-mcp` のディレクトリ作成を追加
- 配置場所は `./workspaces/` ではなく `./data/` 配下（他と一貫させるため）

### Next Checks
- If title generation regresses, inspect the latest remote OpenCode log for `agent=title` and `failed to generate title`; the model should now be `deepseek-v4-flash-free`, not `gpt-5-nano`.
- Old sessions whose title generation already failed will not automatically retry unless manually renamed or retriggered by code/API.
