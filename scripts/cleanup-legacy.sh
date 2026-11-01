
#!/bin/sh
set -eu

BASE=/var/luna-service2-dev
MODE="${1:---dry-run}"

case "$MODE" in
  --dry-run|--apply) ;;
  *)
    echo "Usage: $0 [--dry-run|--apply]" >&2
    exit 2
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: host root privileges required" >&2
  exit 1
fi

for file in \
  "$BASE/manifests.d/com.example.lunapoc.persist.json" \
  "$BASE/services.d/com.example.lunapoc.persist.service" \
  "$BASE/manifests.d/com.example.lunapoc.json" \
  "$BASE/services.d/com.example.lunapoc.service"
do
  if [ ! -e "$file" ] && [ ! -L "$file" ]; then
    echo "SKIP: $file"
    continue
  fi

  if [ "$MODE" = "--dry-run" ]; then
    echo "WOULD REMOVE: $file"
  elif [ -f "$file" ] && [ ! -L "$file" ]; then
    rm -- "$file"
    echo "REMOVED: $file"
  else
    echo "SKIP unusual file type: $file"
  fi
done

if [ "$MODE" = "--apply" ]; then
  /usr/sbin/ls-control scan-volatile-dirs
fi

echo "Cleanup finished: $MODE"
