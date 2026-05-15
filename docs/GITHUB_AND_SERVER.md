# GitHub Upload and Server Import

This guide gets the project from your local machine to GitHub, then from GitHub to the AWS Ubuntu server.

## 1. Local Safety Check

Before uploading, make sure no real secrets are present:

```powershell
git status --short
git check-ignore -v .env
git check-ignore -v .cache/sources/new-api.zip
```

Expected:

- `.env` should be ignored.
- `.cache/` should be ignored.
- `.env.example` should not be ignored.

## 2. Create a GitHub Repository

Create an empty repository on GitHub, for example:

```text
ai-service-platform
```

Do not initialize it with a README on GitHub if you are pushing this local project as the first commit.

## 3. Push From Windows

From this project root:

```powershell
git init
git branch -M main
git add .
git commit -m "Initial AI service platform deployment"
git remote add origin https://github.com/<your-org>/ai-service-platform.git
git push -u origin main
```

If Git asks for identity:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

If GitHub password authentication fails, use a GitHub personal access token as the password, or use GitHub Desktop.

## 4. Import on AWS Ubuntu

SSH into the server:

```bash
ssh ubuntu@YOUR_SERVER_IP
```

Install Docker if needed:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-org>/ai-service-platform/main/scripts/install-docker-ubuntu.sh | bash
```

Log out and log back in after Docker installation.

Clone your repository:

```bash
git clone https://github.com/<your-org>/ai-service-platform.git
cd ai-service-platform
```

Create the real environment file:

```bash
cp .env.example .env
nano .env
```

Change every `change-me` value and all domain values.

Validate and start:

```bash
cd infra
docker compose --env-file ../.env config
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d
```

## 5. Server Update Flow

After future changes:

```bash
cd ai-service-platform
git pull
cd infra
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d --build
```

Use `--build` when you enable local source builds through `docker-compose.source.yml`.

## 6. Source Build Flow

When you start modifying `new-api`, `sub2api`, or `open-webui`:

```bash
cd infra
cp docker-compose.source.example.yml docker-compose.source.yml
docker compose --env-file ../.env -f docker-compose.yml -f docker-compose.source.yml up -d --build
```

Commit `docker-compose.source.yml` only if you want the server to always build from local source. Otherwise keep it as a server-local choice.
