
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TV="${TV_HOST:-lg-tv}"
MAC_IP="${MAC_IP:-192.168.10.23}"
PORT="${BOOTSTRAP_PORT:-8765}"

URL="http://${MAC_IP}:${PORT}/browser-test.html"
SERVER_PID=""

cleanup() {
    if [[ -n "$SERVER_PID" ]]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

echo "=== webOS Bootstrap ==="

# Vérifier qu'un autre serveur n'utilise pas le port.
if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "ERROR: Port $PORT already in use." >&2
    exit 1
fi

echo "[1/3] Starting HTTP server..."

python3 -m http.server "$PORT" \
    --bind 0.0.0.0 \
    --directory "$ROOT/bootstrap" &

SERVER_PID=$!

echo "[2/3] Waiting for HTTP server..."

READY=false

for ((i=0; i<30; i++)); do
    if curl --fail --silent --head \
        "http://127.0.0.1:${PORT}/browser-test.html" \
        >/dev/null 2>&1; then
        READY=true
        break
    fi
    sleep 0.2
done

if [[ "$READY" != true ]]; then
    echo "ERROR: HTTP server failed to start." >&2
    exit 1
fi

echo "[3/3] Opening tinybrowser..."

PAYLOAD=$(printf \
    '{"id":"com.webos.app.tinybrowser","params":{"contentTarget":"%s"}}' \
    "$URL")

ssh "$TV" \
    "luna-send-pub -n 1 -w 5000 luna://com.webos.applicationManager/launch '$PAYLOAD'"

echo
echo "Page opened: $URL"
echo "Press Enter once the page is displayed on your TV."
read -r _

echo "Done."
