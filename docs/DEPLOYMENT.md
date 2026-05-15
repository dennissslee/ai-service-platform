# AWS Ubuntu 26.04 Docker Compose Deployment

This deployment runs one public reverse proxy plus independent backend services:

- `portal`: unified website / jump page
- `new-api`: single-model API relay
- `sub2api`: lightweight user service
- `litellm`: enterprise multi-model gateway
- `open-webui`: web chat UI
- `caddy`: HTTPS reverse proxy

The first version does not include unified login. Each service keeps its own account and admin model.

## 1. Server Preparation

Point DNS records to the public IP of your AWS server:

- `PORTAL_DOMAIN`
- `NEW_API_DOMAIN`
- `SUB2API_DOMAIN`
- `LITELLM_DOMAIN`
- `OPEN_WEBUI_DOMAIN`

Open inbound ports in the AWS security group:

- `80/tcp`
- `443/tcp`
- Optional direct debug ports from `.env`: `8080`, `3000`, `3001`, `4000`, `8081`

Install Docker Engine and Docker Compose plugin on Ubuntu:

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
```

Log out and log back in after adding your user to the `docker` group.

## 2. Configure Environment

From the project root:

```bash
cp .env.example .env
nano .env
```

Change every value beginning with `change-me`.

At minimum, update:

- All `*_DOMAIN` values
- `NEW_API_POSTGRES_PASSWORD`
- `LITELLM_POSTGRES_PASSWORD`
- `SUB2API_POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `NEW_API_SQL_DSN`
- `NEW_API_REDIS_CONN_STRING`
- `NEW_API_SESSION_SECRET`
- `SUB2API_DATABASE_URL`
- `SUB2API_REDIS_URL`
- `LITELLM_MASTER_KEY`
- `LITELLM_SALT_KEY`
- `LITELLM_UI_PASSWORD`
- `OPEN_WEBUI_SECRET_KEY`
- `OPENAI_API_BASE_URL`
- `OPENAI_API_BASE_URLS`
- `OPENAI_API_KEY`
- `CADDY_EMAIL`

`SUB2API_IMAGE` defaults to `weishaw/sub2api:latest`. After the first successful deployment, consider pinning it to a tested version tag.

Keep `.env` private. Do not commit it.

After `.env` is ready, you can use the helper script from the project root:

```bash
./scripts/deploy.sh
```

## 3. Portal Links

The starter portal lives at:

```text
infra/portal/index.html
```

The portal page is static. In production it infers sibling service domains from the current host. For example, `portal.1.2.3.4.sslip.io` links to `new-api.1.2.3.4.sslip.io`, `sub2api.1.2.3.4.sslip.io`, and the other service hosts.

You can replace the starter page, or replace the `portal` service with your own image by setting:

When opened directly from the filesystem, the same page uses local debug links:

- `http://localhost:3000` for `new-api`
- `http://localhost:3001` for `sub2api`
- `http://localhost:4000` for `litellm`
- `http://localhost:8081` for `open-webui`

Sub2API first-run setup may temporarily listen on container port `8080`, but after setup it can run on container port `443`. Caddy is configured with both upstreams and retries automatically.

```env
PORTAL_IMAGE=your-registry/your-portal:latest
```

If you use a custom portal image, remove or adjust the `./portal:/usr/share/caddy:ro` volume in `infra/docker-compose.yml`.

## 4. Start Services

Run Compose from the `infra` directory and explicitly load the root `.env` file:

```bash
cd infra
docker compose --env-file ../.env config
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d
```

Check status:

```bash
docker compose --env-file ../.env ps
docker compose --env-file ../.env logs -f caddy
```

Caddy will request TLS certificates automatically after DNS points to the server and ports `80` and `443` are reachable.

## 5. Service URLs

Use the domains configured in `.env`:

- Portal: `https://PORTAL_DOMAIN`
- New API: `https://NEW_API_DOMAIN`
- Sub2API: `https://SUB2API_DOMAIN`
- LiteLLM: `https://LITELLM_DOMAIN`
- Open WebUI: `https://OPEN_WEBUI_DOMAIN`

Direct ports are also mapped for debugging and can be changed in `.env`.

## 6. Operations

Restart all services:

```bash
cd infra
docker compose --env-file ../.env restart
```

Update images:

```bash
cd infra
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d
```

View logs for one service:

```bash
cd infra
docker compose --env-file ../.env logs -f litellm
```

Stop services:

```bash
cd infra
docker compose --env-file ../.env down
```

Back up Docker volumes before major upgrades:

- `new_api_postgres_data`
- `litellm_postgres_data`
- `sub2api_postgres_data`
- `redis_data`
- `new_api_data`
- `sub2api_data`
- `litellm_data`
- `open_webui_data`
- `caddy_data`

## 7. Future Changes

The deployment is intentionally loose for phase one:

- Add unified login later at the proxy layer or inside each app.
- Replace the static `portal` with a real web app image.
- Split databases per service if isolation becomes more important.
- Restrict direct debug ports by removing the `ports` mappings from app services and keeping only Caddy public.
- Add service-specific config files for LiteLLM or New API when your model routing stabilizes.

See `docs/CUSTOMIZATION.md` for the recommended path to fork upstream projects and switch selected services from published images to local source builds.
