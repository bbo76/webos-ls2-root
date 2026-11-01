
#!/bin/sh
set -eu

echo "=== Environment ==="
date
id

echo
echo "=== Boot ==="
cat /proc/sys/kernel/random/boot_id
cat /proc/uptime

echo
echo "=== Homebrew ==="
for file in \
  /var/lib/webosbrew/startup.sh \
  /var/luna-service2-dev/manifests.d/org.webosbrew.hbchannel.json \
  /var/luna-service2-dev/services.d/org.webosbrew.hbchannel.service.service
do
  if [ -f "$file" ]; then
    echo "FOUND: $file"
  else
    echo "MISSING: $file"
  fi
done

echo
echo "=== Legacy POC ==="
for file in \
  /var/luna-service2-dev/manifests.d/com.example.lunapoc.persist.json \
  /var/luna-service2-dev/services.d/com.example.lunapoc.persist.service
do
  if [ -e "$file" ]; then
    echo "FOUND: $file"
  else
    echo "ABSENT: $file"
  fi
done
