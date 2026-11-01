
#!/bin/sh
set -eu

APP=/media/developer/apps/usr/palm/services/org.webosbrew.hbchannel.service
MANIFEST=/var/luna-service2-dev/manifests.d/org.webosbrew.hbchannel.json
STARTUP=/var/lib/webosbrew/startup.sh
INSTALLER_URL=https://raw.githubusercontent.com/webosbrew/webos-homebrew-channel/main/tools/install.sh

echo "=== Homebrew Channel Installer ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: root access required."
    exit 1
fi

# Prevent the Homebrew startup script from enabling
# unauthenticated Telnet access.
mkdir -p /var/luna/preferences
touch /var/luna/preferences/webosbrew_telnet_disabled

# An existing installation is not overwritten.
if [ -f "$MANIFEST" ] && \
   [ -x "$APP/elevate-service" ]; then
    echo "Homebrew Channel already installed."
    echo "SKIP: no reinstall or update."
    exit 0
fi

echo "Downloading official installer..."

TMP=/tmp/webosbrew-install-$$.sh
trap 'rm -f "$TMP"' EXIT HUP INT TERM

curl --fail --location --retry 3 \
    "$INSTALLER_URL" \
    --output "$TMP"

test -s "$TMP"
sh -n "$TMP"

echo "Running official installer..."
sh "$TMP"

echo "Installing official startup script..."
mkdir -p /var/lib/webosbrew
cp "$APP/startup.sh" "$STARTUP"
chmod 755 "$STARTUP"

echo "Verifying installation..."

test -f "$MANIFEST"
test -x "$APP/elevate-service"
test -x "$STARTUP"

echo "SUCCESS: Homebrew Channel installed."
echo "Final check: open Homebrew Channel."
echo "Expected Root status: OK"
