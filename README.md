# AI Service Platform

统一官网入口 + 多个独立 AI 服务后台的第一阶段部署工程。

## Services

- `portal`: 官网 / 服务跳转页
- `new-api`: 单模型 API 中转
- `sub2api`: 轻量用户服务
- `litellm`: 企业多模型网关
- `open-webui`: 网页聊天界面
- `caddy`: 反向代理与自动 HTTPS

第一阶段各服务独立运行，不做统一登录。后续可以逐步加入支付、额度、统一账号、品牌 UI 和企业管理能力。

## Repository Layout

```text
.
├── .env.example
├── infra/
│   ├── docker-compose.yml
│   ├── docker-compose.source.example.yml
│   ├── caddy/Caddyfile
│   └── portal/
├── services/
│   ├── new-api/
│   ├── sub2api/
│   └── open-webui/
├── scripts/
└── docs/
```

## Quick Start

Validate Compose locally:

```powershell
docker compose --env-file .env.example -f infra/docker-compose.yml config --quiet
```

On the server:

```bash
cp .env.example .env
nano .env
./scripts/deploy.sh
```

Read these docs before deployment:

- `docs/DEPLOYMENT.md`
- `docs/GITHUB_AND_SERVER.md`
- `docs/CUSTOMIZATION.md`
- `docs/SOURCE_IMPORTS.md`

## Secrets

Never commit `.env`. Use `.env.example` as the public template and keep real passwords/API keys only on the server.
