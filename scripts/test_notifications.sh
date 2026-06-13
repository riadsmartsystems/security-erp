#!/bin/bash
# End-to-end NATS notification test for telegram-service
set -euo pipefail

usage() {
  cat <<'EOF'
Docker-only E2E test for Telegram/Viber notifications

Usage:
  ./scripts/test_notifications.sh [TELEGRAM_IDS] [VIBER_IDS]
  ./scripts/test_notifications.sh --telegram-ids "123456789" --viber-ids "VIBER_USER_ID"

Options:
  --telegram-ids  Comma-separated Telegram chat IDs
  --viber-ids     Comma-separated Viber user IDs
  --message       Custom message for notifications.send
  --help          Show this help

Defaults:
  If IDs are not provided, script uses env values:
  TEST_TELEGRAM_IDS / NOTIFICATION_TELEGRAM_CHAT_IDS
  TEST_VIBER_IDS / NOTIFICATION_VIBER_USER_IDS
EOF
}

TG_IDS="${TEST_TELEGRAM_IDS:-${NOTIFICATION_TELEGRAM_CHAT_IDS:-}}"
VIBER_IDS="${TEST_VIBER_IDS:-${NOTIFICATION_VIBER_USER_IDS:-}}"
MESSAGE="Тестова розсилка з NATS (E2E)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --telegram-ids)
      TG_IDS="$2"
      shift 2
      ;;
    --viber-ids)
      VIBER_IDS="$2"
      shift 2
      ;;
    --message)
      MESSAGE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$TG_IDS" ]]; then
        TG_IDS="$1"
      elif [[ -z "$VIBER_IDS" ]]; then
        VIBER_IDS="$1"
      else
        echo "ERROR: Unknown argument: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

echo "=== NATS Notification E2E Test ==="

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed"
  exit 1
fi

echo "1) Building and restarting telegram-service..."
docker compose up -d --build telegram-service

echo "Telegram IDs: ${TG_IDS:-<using service defaults>}"
echo "Viber IDs: ${VIBER_IDS:-<using service defaults>}"

echo "2) Sending custom notification event..."
CMD=(
  docker compose exec -T telegram-service
  python scripts/publish_notification.py
  --subject notifications.send
  --channels telegram viber
  --message "$MESSAGE"
)

if [ -n "$TG_IDS" ]; then
  CMD+=(--telegram-ids "$TG_IDS")
fi

if [ -n "$VIBER_IDS" ]; then
  CMD+=(--viber-ids "$VIBER_IDS")
fi

"${CMD[@]}"

echo "3) Sending SLA breach test event..."
docker compose exec -T telegram-service \
  python scripts/publish_notification.py \
  --subject fsm.sla.breached \
  --ticket-number "TCK-E2E-001" \
  --sla-type resolution \
  --priority critical

echo "4) Recent telegram-service logs..."
docker compose logs --tail 80 telegram-service

echo "=== Done ==="
echo "Tip: ./scripts/test_notifications.sh --telegram-ids \"123456789\" --viber-ids \"VIBER_USER_ID\""
