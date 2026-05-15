$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

$Docker = "docker"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  $Docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
}

& $Docker compose --env-file .env.example -f infra\docker-compose.yml config --quiet
& $Docker compose --env-file .env.example -f infra\docker-compose.yml -f infra\docker-compose.source.example.yml config --quiet

Write-Host "Compose configuration is valid."
