#!/usr/bin/env bash
# Запуск контейнеров с обходом credsStore (Docker Desktop error getting credentials)
#
# Использование:
#   ./run.sh [команда] [профиль]
#
# Команды: build, up, down, logs
# Профили: auto (по умолчанию), download, comfy
#
# Примеры:
#   ./run.sh build auto        # сборка AUTOMATIC1111
#   ./run.sh up auto           # запуск WebUI в фоне
#   ./run.sh up-fg download    # скачать модели (foreground, видно прогресс)
#   ./run.sh down              # остановить

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_CONFIG_DIR="${SCRIPT_DIR}/.docker-build"

# Обход credsStore: Docker Desktop даёт "error getting credentials" при build.
# .docker-build/ не коммитится — создаётся при первом запуске.
if [[ ! -f "${DOCKER_CONFIG_DIR}/config.json" ]]; then
  echo "Создаём .docker-build/config.json (пустой config без credsStore)"
  mkdir -p "$DOCKER_CONFIG_DIR"
  printf '%s\n' '{"auths":{},"currentContext":"default"}' > "${DOCKER_CONFIG_DIR}/config.json"
fi

export DOCKER_CONFIG="${DOCKER_CONFIG_DIR}"

CMD="${1:-up}"
PROFILE="${2:-auto}"

cd "$SCRIPT_DIR"

case "$CMD" in
  build)
    echo "Сборка с DOCKER_CONFIG=$DOCKER_CONFIG_DIR"
    docker compose --profile "$PROFILE" build --no-cache
    ;;
  up)
    echo "Запуск профиля $PROFILE с DOCKER_CONFIG=$DOCKER_CONFIG_DIR"
    docker compose --profile "$PROFILE" up -d
    echo "UI: http://localhost:7860"
    ;;
  up-fg)
    echo "Запуск в foreground (логи в консоль)"
    docker compose --profile "$PROFILE" up --build
    ;;
  down)
    docker compose --profile "$PROFILE" down
    ;;
  logs)
    docker compose --profile "$PROFILE" logs -f
    ;;
  *)
    echo "Неизвестная команда: $CMD"
    echo "Доступно: build, up, up-fg, down, logs"
    exit 1
    ;;
esac
