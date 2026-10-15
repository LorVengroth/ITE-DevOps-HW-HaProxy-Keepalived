#!/usr/bin/env bash
set -euo pipefail

# Determine host identity and services to manage
HOSTNAME=$(hostname)

if [[ "$HOSTNAME" =~ web-0[1-2] ]]; then
    SERVICES=("next-app.service")
elif [[ "$HOSTNAME" =~ lb-0[1-2] ]]; then
    SERVICES=("haproxy" "keepalived")
else
    # Fallback default if hostname doesn't match standard patterns
    SERVICES=("next-app.service")
fi

ACTION="${1:-}"

usage() {
    echo "Usage: $0 {start|stop|restart|status|logs}"
    echo "  start   - Starts the managed service(s)"
    echo "  stop    - Stops the managed service(s)"
    echo "  restart - Restarts the managed service(s)"
    echo "  status  - Displays active status of the service(s)"
    echo "  logs    - Tails the recent system logs for the service(s)"
    exit 1
}

if [ -z "$ACTION" ]; then
    usage
fi

execute_action() {
    local svc="$1"
    local act="$2"

    echo "==> [$HOSTNAME] Processing '$act' for $svc..."

    case "$act" in
        start)
            sudo systemctl start "$svc"
            sudo systemctl is-active --quiet "$svc" && echo "  [✓] $svc is now ACTIVE" || echo "  [✗] Failed to start $svc"
            ;;
        stop)
            sudo systemctl stop "$svc"
            ! sudo systemctl is-active --quiet "$svc" && echo "  [✓] $svc is now STOPPED" || echo "  [✗] Failed to stop $svc"
            ;;
        restart)
            sudo systemctl restart "$svc"
            sudo systemctl is-active --quiet "$svc" && echo "  [✓] $svc RESTARTED successfully" || echo "  [✗] Failed to restart $svc"
            ;;
        status)
            echo "--- Status for $svc ---"
            sudo systemctl status "$svc" --no-pager || true
            ;;
        logs)
            echo "--- Recent logs for $svc ---"
            sudo journalctl -u "$svc" -n 20 --no-pager
            ;;
        *)
            usage
            ;;
    esac
}

for SERVICE in "${SERVICES[@]}"; do
    execute_action "$SERVICE" "$ACTION"
done