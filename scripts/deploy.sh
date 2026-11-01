
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE="/media/developer/temp/ls2root-v01"
TV="${TV_HOST:-lg-tv}"

upload() {
    local source="$1"
    local destination="$2"

    test -s "$source" || {
        echo "ERROR: Empty or missing file: $source" >&2
        exit 1
    }

    ssh "$TV" "cat > '$destination'" < "$source"

    local expected actual
    expected="$(shasum -a 256 "$source" | awk '{print $1}')"
    actual="$(ssh "$TV" "sha256sum '$destination'" | awk '{print $1}')"

    if [[ "$expected" != "$actual" ]]; then
        echo "ERROR: Checksum mismatch: $destination" >&2
        exit 1
    fi

    echo "OK: $destination"
}

echo "=== Deploy LS2 Root V0.1 ==="

ssh "$TV" "
    mkdir -p '$REMOTE/reference-test'
    mkdir -p '$REMOTE/services'
"

upload \
    "$ROOT/bootstrap/manifest.json" \
    "$REMOTE/reference-test/manifest.json"

upload \
    "$ROOT/bootstrap/service" \
    "$REMOTE/services/com.example.ls2root.v01.service"

upload \
    "$ROOT/bootstrap/verify-root.sh" \
    "$REMOTE/verify-root.sh"

ssh "$TV" "chmod 755 '$REMOTE/verify-root.sh'"

echo
echo "Deployment verified."
echo "Register the manifest using Luna Manifest Lab."
