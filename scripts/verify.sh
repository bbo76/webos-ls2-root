#!/usr/bin/env bash
set -euo pipefail

TV="${TV_HOST:-lg-tv}"
REMOTE="/media/developer/temp/ls2root-v01"

echo "=== LS2 Root Verification ==="

# Remove stale output before invoking the service.
ssh "$TV" "rm -f '$REMOTE/result.txt'"

echo "Triggering LS2 service..."
ssh "$TV" \
  'luna-send-pub -n 1 -w 3000 luna://com.example.ls2root.v01/test "{}"' || true

echo
echo "Reading diagnostic..."
RESULT="$(ssh "$TV" "cat '$REMOTE/result.txt' 2>/dev/null")" || {
  echo "ERROR: No diagnostic result." >&2
  exit 1
}

printf '%s\n' "$RESULT"

if printf '%s\n' "$RESULT" | grep -q 'uid=0(root)'; then
  echo
  echo "SUCCESS: LS2 service executed as root."
else
  echo
  echo "ERROR: Root execution not confirmed." >&2
  exit 1
fi
