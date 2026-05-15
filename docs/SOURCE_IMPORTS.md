# Source Imports

The following upstream projects have been imported under `services/` for future customization:

| Service | Local path | Upstream |
| --- | --- | --- |
| `new-api` | `services/new-api` | `https://github.com/Calcium-Ion/new-api` |
| `sub2api` | `services/sub2api` | `https://github.com/Wei-Shaw/sub2api` |
| `open-webui` | `services/open-webui` | `https://github.com/open-webui/open-webui` |

## Import Method

The local network could not connect to `github.com:443` through Git, so the first import used GitHub source zip archives from `codeload.github.com`.

That means these directories currently contain source files but do not include `.git` history. This is enough for reading, editing, and Docker builds. When GitHub access is stable, replace each directory with your own fork clone so future upgrades can use normal Git workflows:

```powershell
Remove-Item -Recurse -Force services/new-api
git clone https://github.com/<your-org>/new-api.git services/new-api

Remove-Item -Recurse -Force services/sub2api
git clone https://github.com/<your-org>/sub2api.git services/sub2api

Remove-Item -Recurse -Force services/open-webui
git clone https://github.com/<your-org>/open-webui.git services/open-webui
```

Only remove these directories after your fork is ready or after you have backed up local changes.

## Build Override

Use the source build override when you want Docker Compose to build from local code:

```bash
cd infra
docker compose --env-file ../.env -f docker-compose.yml -f docker-compose.source.yml up -d --build
```

Start with `new-api` and `sub2api` for payment, quota, and user-service changes. Enable `open-webui` local builds when you start changing the chat interface.
