<div align="center">

<img src="docs/media/logo.svg" width="560" alt="BIOHÓ - a website served from six microcontrollers">

<br>

**https://projectbioho.com**

**A personal website served from six £12 microcontrollers on a shelf in a flat in Berlin.**
No cloud. No CDN. No Raspberry Pi. No reverse-proxy box.

[![Live](https://img.shields.io/badge/site-live-43e86a?style=flat-square)](https://projectbioho.com)
[![ESP-IDF](https://img.shields.io/badge/ESP--IDF-v6.0.2-4d7de0?style=flat-square)](https://docs.espressif.com/projects/esp-idf/)
[![Boards](https://img.shields.io/badge/ESP32--S3-%C3%976-a05de0?style=flat-square)](#hardware)
[![License](https://img.shields.io/badge/license-MIT-e6c229?style=flat-square)](LICENSE)

</div>

---

Four ESP32-S3 blades with wired Ethernet hold an election over encrypted
radio. The winner puts on **the crown** - a virtual MAC address no factory ever
issued, plus the one LAN address the router forwards - and becomes a
**layer-4 TCP splicer**: it accepts your connection and relays the raw bytes
to whichever other blade is least busy. That blade terminates TLS 1.3 and
serves the page out of its own flash.

Kill the leader, and another blade wears the crown in under four seconds -
same MAC, same address, same certificate, different silicon. Kill everything
but one, and the survivor splices to itself over loopback and keeps serving.
Two more boards - a 2.8" roster screen (the **vigía**) and a 4.3" touch
panel (the **cabildo**) - hear every heartbeat and paint the fleet on glass
and on a six-pixel LED rail, one pixel per member.

<img src="docs/media/hero.svg" width="100%" alt="The serving path and the radio control plane">

Named **Project Biohó**, after Benkos Biohó, who broke his chains and built a free town the empire could not take. The capitán wears the crown. The cimarrones answer. The vigía and the cabildo keep the record. A website that refuses a landlord.

## Why it is interesting

- **Load balancing is an elected role, not a box.** Every blade carries both
  programs. The splicer's backend set is rebuilt every second from radio
  gossip; no configuration file names a backend.
- **The election never rides the wire it protects.** Heartbeats travel over
  encrypted ESP-NOW at 1 Hz, so a switch or cable failure cannot split the
  brain. The election is preemptive arithmetic - the lowest healthy, serving
  id leads - with nothing to wedge and nothing to time out.
- **Health is proven twice, from both sides.** Every blade TCP-connects to
  its own public port every 7 seconds and stands down from the election when
  it fails; the splicer independently benches backends by the bytes that
  actually come back, because a self-reported flag can lie.
- **Releases cannot brick the fleet.** One key-gated, variant-guarded OTA
  door for all six members. Deploys roll followers first, leader last, and a
  fresh image must survive a 90-second serving trial or the bootloader rolls
  it back. The radio-only displays update through a touch-opened OTA window
  under the same rollback contract.
- **No reboot goes unexplained.** Every node keeps a 4096-record blackbox
  ring and a coredump partition in flash; the heartbeat carries every boot's
  cause, and the cabildo's chronicle names it on glass.

Measured on the machine itself: fresh TLS connections at **2.9-3.0/s with
nothing dropped** (a ~650 ms P-256 handshake is 99% of the toll), warm
keep-alive requests in ~40-60 ms at ~40-50 req/s fleet-wide, the splicer's
own wire the limit past ~100 req/s - and the site stays up through any
single power plug being pulled.

The full architecture, with every diagram:
**[`docs/SYSTEM_DESIGN.md`](docs/SYSTEM_DESIGN.md)**. How it came to be,
cascade of failures included: **[`STORY.md`](STORY.md)**.

## Firmware

<img src="docs/media/firmware.svg" width="100%" alt="A blade at run time, and one tree becoming three images">

Three images from one tree. `bioho_eth` is the blade: a TLS server pinned
to its own core (a P-256 handshake is 99% of the cost of a visit), the
radio, lwIP and the splicer sharing the other, and a key-gated admin plane
that never leaves the LAN. `bioho_display` and `bioho_mission` are the
witnesses - and they compile the blades' control-plane sources straight
from `firmware/eth/main/` by path, so a display can never drift out of
protocol with the blades it listens to.

The firmware assumes it will fail, and instruments every way it ever has:
each blade TCP-connects its own public port every 7 seconds and stands
down from the election when that fails, a watchdog aborts to a coredump if
the lwIP thread wedges, and a 4096-record blackbox ring in flash survives
reboot, OTA and panic - when a blade dies, it leaves a note saying why.

The rules the fleet lives by - who leads, what availability means, when
the balancer benches a blade - are pure functions in one header,
[`logic.h`](firmware/eth/main/logic.h), proven on the host by
[`tools/run_tests.sh`](tools/run_tests.sh) with ESP-IDF's own Unity
(39 tests, ASan/UBSan). The serving path proves itself on the machine
instead: a fresh image must survive a 90-second public serving trial or
the bootloader rolls it back. Module-by-module detail:
[`docs/firmware/`](docs/firmware/).

## Hardware

A printed shell is the rack: four blades on one plate, both screens, the LED rail, an HPE 1420
switch, and a Mean Well GST60A feeding six fused USB-C sockets. Two 50 mm
exhaust fans go on the lid later, on fused 2-pin screw terminals; there is no
intake fan. About 22 W for the whole machine. The build is documented to be repeatable, from the first solder
joint to the shell: [`docs/hardware/`](docs/hardware/).

## Build your own

You need:

- **2+ LILYGO T-ETH-Lite ESP32-S3 boards** - one serves with no failover;
  this fleet runs four plus two spares.
- An Ethernet switch, a 5 V supply into USB-C leads, a router you can port-forward on, a
  **static public IP**, a domain.
- A computer with [ESP-IDF](https://docs.espressif.com/projects/esp-idf/)
  **v6.0.2** exported in the shell.
- Optional: the two display boards + an SK6812 strip
  ([`docs/hardware/`](docs/hardware/)), the shell, and the bohío
  ([`hardware/`](hardware/)). The plate holds the four cimarrones. The shell
  holds the whole machine.

Then, in order:

1. **Mint your secrets** (once):
   ```bash
   tools/gen_secrets.sh
   ```
   Writes the OTA key and the ESP-NOW PMK/LMK into
   `firmware/eth/main/secrets.h` - gitignored, never committed, baked into
   every binary (which is why build directories are gitignored too). Then
   fill in the deployment fields by hand: `BIOHO_CROWN_IP` (the crown's
   reserved LAN address, outside your DHCP pool), `BIOHO_CROWN_GW` (your
   gateway), and - if you build the displays - `BIOHO_WIFI_SSID`/`_PASS`
   for their OTA window. `secrets.h.example` shows the shape. Keep a copy:
   losing it means USB reflashes to rejoin, and rotating keys is a flag day
   for all nodes at once.

2. **Get a TLS certificate** for your domain (Let's Encrypt via DNS-01
   works while the fleet is still LAN-only) and drop the pair into
   `firmware/eth/main/certs/` as `servercert.pem` (full chain) and
   `prvtkey.pem`. Both gitignored.

3. **Teach the fleet its members** - edit
   `firmware/eth/main/swarm_identity.c`: each board's eFuse MAC, id, name,
   shortname, eligibility. Blades are eligible; displays are witnesses.
   (`idf.py monitor` prints a board's MAC on boot if you need it.)

4. **Make it your site** - replace `assets/personal.html` (one
   self-contained file, no external requests), then refresh the compressed
   copies the firmware embeds:
   ```bash
   gzip -9 -n -c assets/personal.html > firmware/eth/main/personal.html.gz
   brotli -f -q 11 assets/personal.html -o firmware/eth/main/personal.html.br
   ```

5. **Run the tests** - seconds, on your machine, no board:
   ```bash
   tools/run_tests.sh
   ```
   39 checks over the fleet's decision rules (election, availability, the
   balancer's bench), compiled against ESP-IDF's Unity with sanitizers on.
   Run them again after any change to `firmware/eth/main/logic.h`.

6. **First flash of each blade over USB** (every later update goes over the
   air):
   ```bash
   cd firmware/eth
   idf.py -B build.lilygo -D SDKCONFIG=build.lilygo/sdkconfig \
          -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;boards/lilygo.defaults" \
          build flash
   ```
   The per-board defaults matter: they carry 240 MHz, PSRAM and the TLS
   session-ticket config - a plain `idf.py build` produces a slower image
   with a different TLS stack shape.

7. **Displays, if you built them** - plain `idf.py build flash` in
   `firmware/display` and `firmware/mission`. The cabildo additionally
   flashes a baked image of the site into its page partition; regenerate it
   after site changes with `firmware/mission/render_page_asset.py` (needs
   Chrome, nothing else). Later display releases go over the air: hold the
   touch surface for 4 s to open the OTA window, then
   `tools/deploy_observer.sh`
   ([`docs/firmware/ota_deployments.md`](docs/firmware/ota_deployments.md)).

8. **Open the doors** - forward TCP/80 + TCP/443 to your crown address and
   point your domain's A record at your public IP. **Never forward the
   backend or admin ports.**

9. **Prove it**:
   ```bash
   tools/fleet_check.sh
   ```
   Every blade must PASS: page 200, OTA closed on the public port, admin
   open on the LAN, identical content hashes fleet-wide, plus the live
   roster from the crown holder.

10. **Every later release goes over the air**:
   ```bash
   export BIOHO_OTA_KEY=$(grep BIOHO_OTA_KEY firmware/eth/main/secrets.h | cut -d'"' -f2)
   tools/deploy.sh
   ```
   Followers first, leader last, four gates per node including the
   90-second rollback trial. Re-running is idempotent - blades already on
   the target image are skipped.

## Map

| Where | What |
|---|---|
| [`docs/SYSTEM_DESIGN.md`](docs/SYSTEM_DESIGN.md) | **the architecture** - read this first |
| [`STORY.md`](STORY.md) | the build story - how six microcontrollers ended up serving a website |
| [`docs/hardware/`](docs/hardware/) | building the fleet: soldering, power, data wiring, the LED rail, the bohío, the shell |
| [`docs/firmware/`](docs/firmware/) | the firmware: intake, the serving blade, the swarm control plane, both displays, OTA and deploys |
| [`firmware/`](firmware/) | the code: `eth` (blades), `display` (vigía), `mission` (cabildo) - the displays compile the blades' swarm sources by path, no copies |
| [`hardware/`](hardware/) | the rack and the bohío: `shell.scad`, `plate.scad`, `stl/shell_bottom.stl`, `stl/shell_top.stl`, `stl/shell_front_back.stl`, `stl/plate.stl` |
| [`assets/`](assets/) | the site: one self-contained `personal.html` |
| [`firmware/tests/`](firmware/tests/) | host tests for the decision kernels - `tools/run_tests.sh` runs them in seconds |
| [`tools/`](tools/) | `gen_secrets.sh` · `deploy.sh` · `deploy_observer.sh` · `fleet_check.sh` · `fleet_discover.sh` · `run_tests.sh` |

## License

[MIT](LICENSE).
