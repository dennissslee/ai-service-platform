#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${repo_root}/.env"
compose_file="${repo_root}/infra/docker-compose.yml"
source_file="${repo_root}/infra/docker-compose.source.yml"

if [[ ! -f "${env_file}" ]]; then
  echo "Missing .env. Create it from .env.example first." >&2
  exit 1
fi

if [[ ! -f "${source_file}" ]]; then
  echo "Missing infra/docker-compose.source.yml." >&2
  echo "Create it from infra/docker-compose.source.example.yml and enable the services you want to build locally." >&2
  exit 1
fi

cd "${repo_root}/infra"

docker compose --env-file "${env_file}" -f "${compose_file}" -f "${source_file}" config
docker compose --env-file "${env_file}" -f "${compose_file}" -f "${source_file}" up -d --build
docker compose --env-file "${env_file}" -f "${compose_file}" -f "${source_file}" ps
