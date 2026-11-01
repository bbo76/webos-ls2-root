
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TV="${TV_HOST:-lg-tv}"
PORT="${BOOTSTRAP_PORT:-8765}"
MAC_IP="${MAC_IP:-$(ipconfig getifaddr en0 2>/dev/null || true)}"

TMP="$(mktemp -d)"
TOKEN="$(openssl rand -hex 24)"
STATUS="$TMP/status.json"

SERVER_PID=""

cleanup() {
    if [[ -n "$SERVER_PID" ]]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi

    rm -rf "$TMP"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

die() {
    echo "ERROR: $*" >&2
    exit 1
}

echo "=================================="
echo " webOS LS2 Bootstrap V0.2"
echo "=================================="

# ==================================
# 1. Prerequisites
# ==================================

echo
echo "[1/7] Checking SSH..."

ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "$TV" \
    'echo "SSH OK"' \
    || die "SSH connection failed"

echo
echo "[2/7] Checking local files..."

for file in \
    "$ROOT/scripts/deploy.sh" \
    "$ROOT/scripts/verify.sh" \
    "$ROOT/bootstrap/server.py" \
    "$ROOT/bootstrap/index.html"
do
    [[ -s "$file" ]] || die \
        "Missing or empty file: $file"
done

# ==================================
# 2. Check existing service
# ==================================

echo
echo "[3/7] Checking existing LS2 service..."

LS2_OK=false

if TV_HOST="$TV" "$ROOT/scripts/verify.sh" \
    > "$TMP/verify.log" 2>&1; then

    cat "$TMP/verify.log"

    LS2_OK=true

    echo "LS2 diagnostic already operational."
else
    echo "LS2 diagnostic not available."
fi

# ==================================
# 3. Bootstrap if required
# ==================================

if [[ "$LS2_OK" == false ]]; then

    echo
    echo "[4/7] Deploying bootstrap..."

    TV_HOST="$TV" \
        "$ROOT/scripts/deploy.sh"

    [[ -n "$MAC_IP" ]] || die \
        "MAC_IP is missing"

    if lsof -nP \
        -iTCP:"$PORT" \
        -sTCP:LISTEN \
        >/dev/null 2>&1; then

        die "Port $PORT already in use"
    fi

    echo
    echo "[5/7] Starting HTTP server..."

    python3 "$ROOT/bootstrap/server.py" \
        --port "$PORT" \
        --token "$TOKEN" \
        --status-file "$STATUS" \
        > "$TMP/server.log" 2>&1 &

    SERVER_PID=$!

    READY=false

    for ((i=0; i<50; i++)); do

        if curl -fsS \
            "http://127.0.0.1:$PORT/health" \
            >/dev/null 2>&1; then

            READY=true
            break
        fi

        sleep 0.2
    done

    if [[ "$READY" != true ]]; then
        cat "$TMP/server.log" >&2
        die "HTTP server failed to start"
    fi

    echo
    echo "Opening tinybrowser..."

    URL="http://${MAC_IP}:${PORT}/?token=${TOKEN}"

    PAYLOAD="$(printf \
        '{"id":"com.webos.app.tinybrowser","params":{"contentTarget":"%s"}}' \
        "$URL")"

    ssh "$TV" \
        "luna-send-pub -n 1 -w 5000 \
        luna://com.webos.applicationManager/launch \
        '$PAYLOAD'" \
        || die "tinybrowser launch failed"

    echo
    echo "Confirm the slider on your TV."
    echo "Waiting for LS2 registration..."

    STATE=""
    MESSAGE=""

    for ((i=0; i<120; i++)); do

        if [[ -s "$STATUS" ]]; then

            STATE="$(python3 -c \
              'import json,sys;print(json.load(open(sys.argv[1]))["state"])' \
              "$STATUS")"

            MESSAGE="$(python3 -c \
              'import json,sys;print(json.load(open(sys.argv[1]))["message"])' \
              "$STATUS")"

            if [[ "$STATE" == "registered" ||
                  "$STATE" == "error" ]]; then
                break
            fi
        fi

        sleep 1
    done

    if [[ "$STATE" != registered ]]; then
        die "LS2 registration failed: ${MESSAGE:-timeout}"
    fi

    echo "LS2 registration reported."

    # ==================================
    # 4. Independent verification
    # ==================================

    echo
    echo "[6/7] Verifying root execution..."

    
if TV_HOST="$TV" "$ROOT/scripts/verify.sh"; then

    echo "Root execution verified."

    # Publish the verified result for the TV page.
    python3 - "$STATUS" <<'PY'
import json
import sys

with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({
        "state": "verified",
        "message": "Root execution confirmed by verify.sh"
    }, f)
PY

    # Let the browser retrieve the status before
    # stopping the small server.
    sleep 5

else
    python3 - "$STATUS" <<'PY'
import json
import sys

with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({
        "state": "error",
        "message": "Root verification failed"
    }, f)
PY

    sleep 5
    die "Root execution not verified"
fi


fi


# ==================================
# 5. Homebrew Channel
# ==================================

echo
echo "[7/7] Checking Homebrew Channel..."

HBC_APP="org.webosbrew.hbchannel"

# Application Manager is accessible from Developer Mode SSH.
APP_RESPONSE="$(ssh "$TV" \
    "luna-send-pub -n 1 -w 5000 \
    luna://com.webos.applicationManager/getAppLoadStatus \
    '{\"appId\":\"$HBC_APP\"}'")" \
    || die "Unable to query Homebrew installation"

HBC_INSTALLED="$(printf '%s' "$APP_RESPONSE" |
    python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    if data.get("returnValue") is not True:
        raise ValueError(data.get("errorText", "LS2 request failed"))
    print("true" if data.get("exist") is True else "false")
except (ValueError, KeyError) as exc:
    print("ERROR: " + str(exc), file=sys.stderr)
    sys.exit(1)
')" || die "Unable to determine Homebrew installation state"

if [[ "$HBC_INSTALLED" == "true" ]]; then
    echo "Homebrew Channel is already installed."
    echo "SKIP: no reinstall or automatic update."
else
    echo "Homebrew Channel is not installed."

    # An LS2 root diagnostic is not an authenticated root
    # command runner. Use a separately authorized root
    # execution mechanism to invoke the official installer.

    if [[ -z "${ROOT_RUNNER:-}" ]]; then
        die "Homebrew is missing and no authorized root runner is configured"
    fi

    [[ -x "$ROOT_RUNNER" ]] || die \
        "ROOT_RUNNER is not executable"

    echo "Installing Homebrew Channel..."

    "$ROOT_RUNNER" \
        "$ROOT/scripts/install-homebrew-root.sh" \
        || die "Homebrew installation failed"

    echo "Checking application registration..."

    APP_RESPONSE="$(ssh "$TV" \
        "luna-send-pub -n 1 -w 5000 \
        luna://com.webos.applicationManager/getAppLoadStatus \
        '{\"appId\":\"$HBC_APP\"}'")"

    printf '%s' "$APP_RESPONSE" |
        python3 -c '
import json, sys
data = json.load(sys.stdin)
if data.get("returnValue") is not True or data.get("exist") is not True:
    sys.exit("ERROR: Homebrew application not detected")
print("Homebrew application detected.")
' || die "Homebrew post-install verification failed"
fi

echo
echo "Homebrew application check completed."
echo "Final verification: open Homebrew Channel and check Root status OK."
