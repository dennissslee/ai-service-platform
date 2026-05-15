#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${repo_root}/.env"
compose_file="${repo_root}/infra/docker-compose.yml"

if [[ ! -f "${env_file}" ]]; then
  echo "Missing .env. Create it from .env.example first:" >&2
  echo "  cp .env.example .env" >&2
  exit 1
fi

cd "${repo_root}/infra"

docker compose --env-file "${env_file}" -f "${compose_file}" config
docker compose --env-file "${env_file}" -f "${compose_file}" pull
docker compose --env-file "${env_file}" -f "${compose_file}" up -d
docker compose --env-file "${env_file}" -f "${compose_file}" ps
