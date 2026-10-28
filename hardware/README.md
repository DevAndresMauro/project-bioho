# The shell and the bohío

The shell is the rack. It holds the switch, the GST60A, the fuse board, the bohío, and both screens. Outside 247 × 236 × 102 mm.

The plate is the bohío. The four cimarrones share it, side by side. There is no case per blade.

| File | What it is |
|---|---|
| `shell.scad` | the rack. Preview with `part="both"`. Print `tub`, `lid`, and `faces` |
| `plate.scad` | the bohío: four blade nests and a well for each USB-C breakout |
| `stl/shell_bottom.stl` | the tub, `part="tub"`. Floor on the bed |
| `stl/shell_top.stl` | the lid, `part="lid"`. Outer face on the bed, lip up |
| `stl/shell_front_back.stl` | front and rear, `part="faces"`. Outer face on the bed, side by side |
| `stl/plate.stl` | the bohío, from `plate.scad`. 104.9 × 157.7 × 8.2 mm |

Open either source in OpenSCAD. The assembled shell is 247 × 236 × 102 mm, so the tub fits a 256 mm bed. The shell prints from the three meshes above. Front and rear share one file and print outer-face down.

## Print

PETG. 0.2 mm layers, 3 perimeters, 20% infill, no supports.

- Shell: floor flat. Front and rear faces print outer-face down and drop into channels. The lid keeps them from lifting out. Rubber feet go on after printing.
- Bohío: deck on the bed, nests up. Each nest is the board plus 0.6 mm a side.

## Assembly

The bohío tapes to the switch top. Each cimarrón sits in a nest, RJ45 toward the rear, USB-C breakout in the well in front of it. The shell goes around that stack. Screen openings are in the front wall: vigía on the left, cabildo on the right.

## Air

No intake fan. Later, two ALMOCN 5010 fans (50 × 50 × 10 mm, 5 V) sit on the outside of the lid and blow out. The lid vents are the outlet path; the floor vents are the inlet. Each fan has its own fused 2-pin screw terminal on the stripboard. The part is [Amazon B0FCC53X7Y](https://www.amazon.de/dp/B0FCC53X7Y).
