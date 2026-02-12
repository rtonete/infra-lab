#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

if [ ! -f .previous_version ]; then
  error "Nenhuma versão anterior encontrada"
  exit 1
fi

PREVIOUS_VERSION=$(cat .previous_version)

log "Rollback para versão $PREVIOUS_VERSION"

sed -i "s/^APP_VERSION=.*/APP_VERSION=$PREVIOUS_VERSION/" .env

docker compose down
docker compose up -d

log "Rollback concluído"
