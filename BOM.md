# Bill of materials

Everything the fleet needs, as built now. The shell is the rack. The plate on the switch is the bohío, and the four cimarrones sit in it as bare boards, soldered to their USB-C breakouts. The 5 V rail is the GST60A and the fused stripboard. The UGREEN charger and the Tenda SG108 are not part of this build. Hardware detail: [`docs/hardware/`](docs/hardware/). Printable geometry:  
[`hardware/README.md`](hardware/README.md).

## 1. Compute

| Qty | Item | Spec |
|---|---|---|
| 4 | Blade | LILYGO T-ETH-Lite, ESP32-S3 + W5500 |
| 4 | USB-C breakout | Adafruit downstream breakout. One per blade. The three shapes already on the bench are fine |
| 0.5 m | White hook-up | 22 AWG stranded. D− to blade pin 19, four short tails |
| 0.5 m | Green hook-up | 22 AWG stranded. D+ to blade pin 20, four short tails |

Each breakout is soldered with four wires: red VBUS → `5V-IN`, black GND → `GND`, white D− → pin 19, green D+ → pin 20. CC and SBU holes stay empty. On the upright breakouts, D+ and D− are swapped on the silk; follow the labels.

No pin-header strips on the blades. No Dupont jumpers between breakout and blade.

## 2. Displays and the light bar

| Qty | Item | Spec |
|---|---|---|
| 1 | Cabildo | Waveshare ESP32-S3-Touch-LCD-4.3B, bare board, no case. About 8 mm thick; green terminals along the bottom edge |
| 1 | Vigía computer | diymore ESP32-S3 DevKitC N16R8 |
| 1 | Vigía glass | 2.8" ST7789 module, about 50 × 70 mm, about 6 mm thick. Factory 13-pin loom stays |
| 1 | DevKitC headers | The two strips supplied with the DevKitC, if they are not already soldered. The TFT loom and the LED jumpers push onto these |
| 1 | LED strip | SK6812 RGBW, one 6-pixel segment, silicone sleeve and factory plug kept |
| 1 | Level shifter | 74AHCT125, DIP-14 |
| 1 | Shifter board | ElectroCookie half board |
| 1 | Resistor | 330 Ω (anything 250–600 Ω) |
| 6 | Dupont jumper | Female–female, intact. Three DevKitC to shifter, three into the PH casing |
| 1 | Plug housing | 3-pin PH casing, contacts taken from Dupont jumpers, for the strip’s factory plug |
| 1 m | Solid-core, red / green / black | Shifter board links. Green is the LED data colour |

Only if the strip ever flickers: one 470–1000 µF electrolytic at the head of the strip. Do not buy it up front.

## 3. Network

| Qty | Item | Spec |
|---|---|---|
| 1 | Switch | HPE OfficeConnect 1420 8G, JH329A. Fanless, unmanaged, gigabit. 157.7 × 104.9 × 26.9 mm |
| 1 | Switch mains lead | The adapter or cord supplied with the 1420. It does not join the 5 V rail |
| 4 | Patch lead | Cat6 UTP, 0.3 m, labelled n1–n4 |
| 1 | Uplink | Cat6 UTP, long enough to reach the router’s LAN port |

Port map: p1–p4 = N1–N4, p5 = uplink, p6–p8 free. The blades are 10/100 on a gigabit switch.

## 4. Power

| Qty | Item | Spec |
|---|---|---|
| 1 | 5 V brick | Mean Well GST60A05-P1J. 5 V, 6 A, 30 W. Barrel 5.5 × 2.1 mm, center positive. Cord is not in the box |
| 1 | Mains lead | BS 1363 to right-angle IEC C13, 1 m |
| 1 | Barrel socket | 5.5 × 2.1 mm panel jack, center positive, solder tags |
| 6 | USB-C socket | Female, through-hole. Power only: solder plus and minus. N1–N4, vigía, cabildo |
| 2 | Screw terminal | 2-pin. Fused fan branches. The fans are not fitted |
| 6 | Fuse | Bourns MF-R110, 1.1 A hold. N1–N4 and the two fan terminals |
| 2 | Fuse | Bourns MF-R185, 1.85 A hold. Vigía and cabildo. MF-R200 if R185 is out of stock |
| 1 | Stripboard | 0.1 inch pitch, 70 × 90 mm |
| 1 m | Red hook-up | 22 AWG stranded tinned copper. +5 V bus, and the four VBUS tails |
| 1 m | Black hook-up | 22 AWG stranded tinned copper. Ground bus, and the four GND tails |
| 4 | C-to-C lead | USB 2.0, 0.5 m. USB-C both ends. Fuse board into each blade breakout |
| 2 | C-to-C lead | USB 2.0, 1 m. USB-C both ends. Vigía and cabildo |
| 2 | Fan lead | Lands on a 2-pin screw terminal. Fans are a later step |
| 2 | C-to-C lead | The cables already used to flash. Laptop only |

One blade, one 5 V source. Flash by pulling that blade’s C-to-C off the rail and plugging the laptop’s C-to-C into the same breakout.

Cut the copper strip between each fuse’s legs. Fuses sit in the positive lead only. Six USB-C sockets, plus and minus only, and two fused 2-pin screw terminals for the fans. Forty-seven joints: 12 on the USB-C ports, 12 holding those ports down, 16 on the eight fuses, 3 on the barrel jack, 4 on the screw terminals. The blade breakouts still carry D+ and D− to the ESP32.

## 5. Air

No intake fan. Two 50 mm exhaust fans sit on the outside of the lid and blow out. They are a later step. The fuse board already has a fused 2-pin screw terminal for each, so the leads land without reworking the rail.

| Qty | Item | Spec |
|---|---|---|
| 2 | Lid exhaust fan | ALMOCN 5010, 50 × 50 × 10 mm, 5 V USB, lead about 1 m. 0.08 A rated, 0.20 A max. Oil bearing, about 4200 rpm, 3 CFM. Pack of four, use two. [Amazon B0FCC53X7Y](https://www.amazon.de/dp/B0FCC53X7Y) |

## 6. Enclosure

The shell prints from three meshes in `hardware/stl/`, exported from `hardware/shell.scad`. The assembled shell is 247 × 236 × 102 mm. The bohío mesh is `hardware/stl/plate.stl`.

| Qty | Item | Spec |
|---|---|---|
| 1 | Shell tub | `hardware/stl/shell_bottom.stl`, `part="tub"`. Flat floor, vents under the switch. Fits a 256 mm bed |
| 1 | Shell lid | `hardware/stl/shell_top.stl`, `part="lid"`. Outer face on the bed. Vents and the two fan openings are the outlet path |
| 1 | Front and rear faces | `hardware/stl/shell_front_back.stl`, `part="faces"`. Two pieces, outer face on the bed. Front: vigía on the left, cabildo on the right, LED slot and shelf. Rear: switch openings on the right, mains plug opening on the left |
| 1 | Bohío | the plate. `hardware/stl/plate.stl`, from `hardware/plate.scad`. Taped to the top of the 1420. Four blade nests, four breakout wells. 104.9 × 157.7 × 8.2 mm |
| 1 spool | Filament | PETG. 0.2 mm layers, 3 perimeters, 20% infill, no supports. Bed at least 256 mm |
| 1 | Foam tape | Double-sided, to hold the plate on the switch |
| 4 | Rubber feet | Adhesive. Stick on after the tub is printed |

## 7. Bench

| Qty | Item | Spec |
|---|---|---|
| 1 | Solder | 63/37 |
| 1 | Iron, flux, wick, strippers, flush cutters | — |
| 1 | Multimeter | Continuity and DC volts |
| 1 | Label stock | Board stickers `node-1`…`node-4`, `display`, `cabildo`. Lead flags `n1`–`n4`, `uplink` |

## Not in this build

- UGREEN Nexode 200 W charger
- Tenda SG108 and its barrel wart
- Male pin headers on the blades
- The 16 female–female Duponts that used to run from breakout to blade
