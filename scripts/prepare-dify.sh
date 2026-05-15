#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dify_dir="${repo_root}/services/dify"
dify_docker_dir="${dify_dir}/docker"

public_ip="${PUBLIC_IP:-}"
if [[ -z "${public_ip}" ]]; then
  public_ip="$(curl -fsS https://api.ipify.org 2>/dev/null || true)"
fi
if [[ -z "${public_ip}" ]]; then
  public_ip="$(hostname -I | awk '{print $1}')"
fi

dify_host="${DIFY_HOST:-dify.${public_ip}.sslip.io}"
dify_public_url="${DIFY_PUBLIC_URL:-https://${dify_host}}"

random_secret() {
  openssl rand -base64 42 | tr -d '\n'
}

set_env() {
  local key="$1"
  local value="$2"
  local file="${dify_docker_dir}/.env"

  if grep -qE "^${key}=" "${file}"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "${file}"
  else
    printf '\n%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

get_env() {
  local key="$1"
  local file="${dify_docker_dir}/.env"

  grep -E "^${key}=" "${file}" | tail -n 1 | cut -d= -f2- || true
}

ensure_secret() {
  local key="$1"
  local existing
  existing="$(get_env "${key}")"

  if [[ -z "${existing}" || "${existing}" == difyai123456 || "${existing}" == dify-sandbox ]]; then
    existing="$(random_secret)"
    set_env "${key}" "${existing}"
  fi

  printf '%s' "${existing}"
}

if [[ ! -d "${dify_dir}/.git" ]]; then
  mkdir -p "$(dirname "${dify_dir}")"
  git clone --depth 1 https://github.com/langgenius/dify.git "${dify_dir}"
else
  git -C "${dify_dir}" pull --ff-only
fi

if [[ ! -f "${dify_docker_dir}/.env" ]]; then
  cp "${dify_docker_dir}/.env.example" "${dify_docker_dir}/.env"
fi

set_env CONSOLE_API_URL "${dify_public_url}"
set_env CONSOLE_WEB_URL "${dify_public_url}"
set_env SERVICE_API_URL "${dify_public_url}"
set_env TRIGGER_URL "${dify_public_url}"
set_env APP_API_URL "${dify_public_url}"
set_env APP_WEB_URL "${dify_public_url}"
set_env FILES_URL "${dify_public_url}"
set_env ENDPOINT_URL_TEMPLATE "${dify_public_url}/e/{hook_id}"
set_env NEXT_PUBLIC_SOCKET_URL "wss://${dify_host}"

set_env NGINX_HTTPS_ENABLED "false"
set_env EXPOSE_NGINX_PORT "18080"
set_env EXPOSE_NGINX_SSL_PORT "18443"

ensure_secret SECRET_KEY >/dev/null
ensure_secret INIT_PASSWORD >/dev/null
ensure_secret DB_PASSWORD >/dev/null
redis_password="$(ensure_secret REDIS_PASSWORD)"
set_env CELERY_BROKER_URL "redis://:${redis_password}@redis:6379/1"
ensure_secret SANDBOX_API_KEY >/dev/null
ensure_secret PLUGIN_DAEMON_KEY >/dev/null
ensure_secret PLUGIN_DIFY_INNER_API_KEY >/dev/null
weaviate_api_key="$(ensure_secret WEAVIATE_API_KEY)"
set_env WEAVIATE_AUTHENTICATION_APIKEY_ALLOWED_KEYS "${weaviate_api_key}"

cat <<EOF
Dify source and .env are prepared.

Location:
  ${dify_docker_dir}

Planned public URL:
  ${dify_public_url}

Important:
  This script does not start Dify yet.
  Dify's internal nginx is prepared for host ports 18080 and 18443 to avoid taking ports 80 and 443 from the current Caddy stack.

Tomorrow, after we add the Caddy route, we can start it with:
  cd ${dify_docker_dir}
  docker compose --env-file .env pull
  docker compose --env-file .env up -d
EOF
