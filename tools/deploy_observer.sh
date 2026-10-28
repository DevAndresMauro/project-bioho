#!/usr/bin/env bash
# deploy_observer.sh - push a build through an observer's open OTA window.
#
# The observers (vigía, cabildo) are radio-only; there is no standing address
# to deploy to. Hold the touch surface for 4 s, read the address off the glass
# (the LED rail turns cyan on the vigía), then:
#
#   tools/deploy_observer.sh display <ip>          # app -> vigía
#   tools/deploy_observer.sh mission <ip>          # app -> cabildo
#   tools/deploy_observer.sh mission <ip> --page   # page strip -> cabildo
#
# No gates, no fleet order - a window push touches one observer, and the boot
# trial (60 s alive + a peer heard, or rollback) is the safety net. Needs
# BIOHO_OTA_KEY in the environment (recipe printed by gen_secrets.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

VARIANT="${1:-}"; IP="${2:-}"; WHAT="${3:-}"
[ -n "$VARIANT" ] && [ -n "$IP" ] || {
    echo "usage: $0 display|mission <ip> [--page]" >&2; exit 2; }
[ -n "${BIOHO_OTA_KEY:-}" ] || {
    echo "BIOHO_OTA_KEY not set - see tools/gen_secrets.sh output" >&2; exit 2; }

case "$VARIANT" in
display) BIN="${BIN:-firmware/display/build/bioho_display.bin}" ;;
mission) BIN="${BIN:-firmware/mission/build/bioho_mission.bin}" ;;
*) echo "unknown variant '$VARIANT'" >&2; exit 2 ;;
esac
DOOR="/ota"
if [ "$WHAT" = "--page" ]; then
    [ "$VARIANT" = "mission" ] || { echo "--page is cabildo-only" >&2; exit 2; }
    BIN="firmware/mission/main/page_strip.bin"
    DOOR="/page"
fi
[ -f "$BIN" ] || { echo "no $BIN - build first" >&2; exit 2; }

SIZE=$(wc -c < "$BIN" | tr -d ' ')
echo "pushing $BIN ($((SIZE / 1024)) KB) -> https://$IP:8443$DOOR"
# -k: the window serves the fleet's self-signed cert on a DHCP address
rm -f /tmp/otaw_resp /tmp/otaw_err
HTTP=$(curl -sSk -o /tmp/otaw_resp -w '%{http_code}' \
        --connect-timeout 10 --max-time 600 \
        -H "X-Bioho-Key: $BIOHO_OTA_KEY" \
        --data-binary @"$BIN" "https://$IP:8443$DOOR" 2>/tmp/otaw_err) || HTTP=000
if [ "$HTTP" != 200 ]; then
    echo "push FAILED (http $HTTP)"
    [ -s /tmp/otaw_err ]  && sed 's/^/  curl: /' /tmp/otaw_err
    [ -s /tmp/otaw_resp ] && sed 's/^/  node: /' /tmp/otaw_resp
    echo "  is the window still open, and is $IP the address on the glass RIGHT NOW?"
    exit 1
fi
echo "http 200: $(cat /tmp/otaw_resp 2>/dev/null)"
if [ "$DOOR" = "/ota" ]; then
    echo "observer reboots into the new image - trial: 60 s alive + a peer heard, else rollback"
else
    echo "power-cycle the cabildo (or wait for its next boot) to render the new page"
fi
