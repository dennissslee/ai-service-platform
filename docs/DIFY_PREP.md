# Dify Preparation

This note keeps Dify ready for the next UI and frontend phase without disturbing the platform that is already running.

## Current Decision

Dify will be prepared as a separate upstream project under `services/dify`, but that directory is ignored by Git. This keeps the main repository light while still letting the server clone the official Dify source when we need it.

Do not start Dify yet. Its official Docker stack includes its own nginx service and many supporting containers, so we should connect it carefully after the existing portal, new-api, sub2api, LiteLLM, Open WebUI, and Caddy stack is stable.

## Why Separate First

- Dify uses a larger Docker Compose stack than the other services.
- Dify's official nginx defaults to host ports `80` and `443`, which are already used by our Caddy reverse proxy.
- We want Dify available for UI/frontend work tomorrow, but we do not want it to break the current site tonight.

## Prepared Shape

The helper script `scripts/prepare-dify.sh` will:

- clone the official Dify repository into `services/dify`;
- create `services/dify/docker/.env` from Dify's `.env.example`;
- set Dify's public URL to an `sslip.io` test domain, for example `https://dify.16.52.35.25.sslip.io`;
- move Dify's own nginx host ports to `18080` and `18443` so it does not conflict with Caddy;
- generate server-local secrets for Dify.

## Server Command

Run this only when we are ready to prepare the files on the server:

```bash
cd ~/ai-service-platform
git pull
bash scripts/prepare-dify.sh
```

This command prepares Dify only. It does not start Dify.

## Tomorrow's Plan

1. Add a Caddy route for `dify.<server-ip>.sslip.io`.
2. Start Dify's official Docker Compose stack.
3. Open the Dify console and finish first-time admin setup.
4. Check where Dify frontend UI can be customized.
5. Decide whether to keep Dify as an upstream source folder or fork it for deeper UI changes.

## Official References

- Official Dify repository: `https://github.com/langgenius/dify`
- Official Docker Compose file: `https://github.com/langgenius/dify/blob/main/docker/docker-compose.yaml`
- Official Docker environment example: `https://github.com/langgenius/dify/blob/main/docker/.env.example`
