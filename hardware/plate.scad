// ============================================================================
// PLATE - the bohío. One PETG tray on top of the HPE 1420.
// Four cimarrones, bare boards, and a well for each USB-C breakout.
// The tray sits inside the shell.
//
// The RJ45 on each blade faces the back, through a slot a bit wider than
// the USB-C one. The USB-C plug faces the front, through a 12 mm slot.
// Between them, one centered slot lets the wires cross from the ESP32
// to its breakout. The side walls stay solid.
//
// The tray is the same size as the switch top. Double-sided tape holds it.
// A skirt that hooked under the switch would need supports, so it is not here.
//
// AXES, installed:
//   x  depth, 0 at the port face (the back), growing toward the front
//   y  width, left to right
//   z  up, z=0 on the switch lid
//
// PRINT flat, deck on the bed, nests up. PETG, 0.2 mm, 3 perimeters,
// 20% infill, no supports. Each nest is the board plus 0.6 mm a side.
// ============================================================================

sw_w = 157.7;
sw_d = 104.9;
deck = 3.2;

board_l = 61;          // depth, jack end to the far end
board_w = 29;          // width
board_x = 12;          // jack end. The plug leaves off the port edge.
wall_t  = 1.4;
wall_h  = 5;           // blade nests and breakout wells, one height
slack   = 0.6;         // extra around the PCB, per side

bay_x = board_x + board_l + 3;
bay_l = 15;            // breakout depth
bay_w = 21;            // breakout width
usb_slot = 12;         // front of each breakout
rj_slot  = 14;         // back of each blade
cable_w  = 12;         // centered, between the blade and its breakout

$fn = 16;

module deck() {
    cube([sw_d, sw_w, deck]);
}

// A wall across y, with one centered slot.
module lip(x, y, span, slot) {
    side = (span - slot) / 2;
    translate([x, y, deck])
        cube([wall_t, side, wall_h]);
    translate([x, y + side + slot, deck])
        cube([wall_t, side, wall_h]);
}

module blade_nest(y) {
    x0 = board_x - slack;
    y0 = y - slack;
    len = board_l + slack;
    wid = board_w + 2 * slack;
    span = wid + 2 * wall_t;
    // side walls, solid
    translate([x0, y0 - wall_t, deck])
        cube([len, wall_t, wall_h]);
    translate([x0, y0 + wid, deck])
        cube([len, wall_t, wall_h]);
    // back: RJ45. Front of this nest: cable slot toward the breakout.
    lip(x0 - wall_t, y0 - wall_t, span, rj_slot);
    lip(x0 + len, y0 - wall_t, span, cable_w);
}

// Well in front of the blade. Back wall carries the same cable slot.
// Front wall has the USB-C slot.
module breakout_well(y) {
    iw = bay_w + 2 * slack;
    il = bay_l + 2 * slack;
    y0 = y + board_w / 2 - iw / 2;
    span = iw + 2 * wall_t;
    translate([bay_x + wall_t, y0 - wall_t, deck])
        cube([il, wall_t, wall_h]);
    translate([bay_x + wall_t, y0 + iw, deck])
        cube([il, wall_t, wall_h]);
    lip(bay_x, y0 - wall_t, span, cable_w);
    lip(bay_x + wall_t + il, y0 - wall_t, span, usb_slot);
}

module plate() {
    pitch = sw_w / 4;
    deck();
    for (i = [0 : 3]) {
        y = pitch * i + (pitch - board_w) / 2;
        blade_nest(y);
        breakout_well(y);
    }
}

plate();
