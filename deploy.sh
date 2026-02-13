
#!/usr/bin/env bash

CURRENT_VERSION_FILE=".current_version"
set -Eeuo pipefail

# ====== CONFIG ======
APP_NAME="infra-lab"
COMPOSE_DIR="infra-compose"
HEALTHCHECK_URL="http://localhost"
TIMEOUT=60

# ====== LOG ======
log() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

# ====== TRAP ======
trap 'error "Erro inesperado na linha $LINENO"; exit 1' ERR

# ====== SAVE CURRENT VERSION ======
save_current_version() {
  if [ -f "$CURRENT_VERSION_FILE" ]; then
    PREVIOUS_VERSION=$(cat "$CURRENT_VERSION_FILE")
    echo "$PREVIOUS_VERSION" > .previous_version
  fi
}

# ====== UPDATE VERSION ======

update_version() {
  echo "$APP_VERSION" > "$CURRENT_VERSION_FILE"
}


# ====== CHECKS ======
check_dependencies() {
  command -v docker >/dev/null 2>&1 || error "Docker não instalado"
  command -v docker compose >/dev/null 2>&1 || error "Docker Compose não disponível"
}

# ====== DEPLOY ======
deploy() {
  log "Entrando no diretório do compose"
  cd "$COMPOSE_DIR"

  log "Atualizando código"
  git pull --rebase

  log "Parando serviços (se existirem)"
  docker compose down

  log "Subindo serviços"
  docker compose up -d
}

# ====== HEALTHCHECK ======
healthcheck() {
  log "Validando saúde da aplicação via namespace do proxy"

  local start_time
  start_time=$(date +%s)

  while true; do
    if docker exec infra-compose-proxy-1 \
      wget -qO- http://localhost/web1/ >/dev/null 2>&1; then
      log "Aplicação saudável (proxy respondeu)"
      break
    fi

    if (( $(date +%s) - start_time > TIMEOUT )); then
      error "Healthcheck falhou após ${TIMEOUT}s"
      exit 1
    fi

    sleep 5
  done
}

# ====== MAIN ======
main() {
  log "Iniciando deploy de $APP_NAME"

  check_dependencies
  save_current_version
  deploy
  healthcheck
  update_version
	
  log "Deploy finalizado com sucesso"
}

main

