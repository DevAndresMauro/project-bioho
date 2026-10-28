// ============================================================================
// SHELL - the rack. Tub and lid for the whole machine.
// BIOHÓ. One print holds the 1420, the GST60A, the fuse board, the bohío
// (the blade plate), and the two bare screens.
//
// AXES:
//   x  depth, front wall at 0, rear wall at ol
//   y  width, left at 0
//   z  up
//
// FRONT, left to right: the 2.8" screen, open floor, the 4.3" mission screen.
// The LED slot stays high on that wall, 45 mm wide and centered.
// The fuse board sits on the floor in front of the switch, lined up with
// the switch's right side. To its left, the GST60A, the vigía DevKitC, and
// the level-shifter breakout sit on tape. The switch is on the right, ports
// against the rear wall. The switch ports open through the right slot.
// The Meanwell mains plug passes through the left slot.
//
// REAR. The right opening matches the switch. A second opening, the same
// width, sits 9 mm above it and is 14 mm tall. The left one is a little
// larger than the brick so the plug can go through. Both lower openings
// start 4 mm above the floor.
//
// PRINT. PETG, 0.2 mm layers, 3 perimeters, 20% infill, no supports.
// The floor is flat. Rubber feet go on after printing.
// The front and the rear faces print together, outer-face down. Each drops
// into a channel from the top, and the lid keeps it from lifting out.
// Outside is 247 x 236 x 102 mm, so it fits a 256 mm bed.
// Print files: part="tub" (shell_bottom.stl), part="lid" (shell_top.stl),
// part="faces" (shell_front_back.stl). "both" is the preview.
// ============================================================================

part = "both";   // "tub" | "lid" | "faces" | "front" | "rear" | "both"

// ---- shell ----
wall    = 2.4;
floor_t = 2.4;
lid_t   = 2.4;
lip_d   = 3;
lip_fit = 0.40;
bite    = 0.6;

// Outside width and depth. Height is the floor plus the inside height.
out_w = 247;
out_l = 236;
in_w = out_w - 2 * wall;
in_h = 100;

// ---- pieces, measured from the inside front-left-floor corner ----
// GST60A05-P1J is 125 long x 50 wide x 31.5 tall.
// Long axis runs front to back. The inlet is the rear short end.
brick_x = 58;  brick_y = 10;  brick_dx = 125;  brick_dy = 50;  brick_h = 31.5;

// HPE OfficeConnect 1420 8G, JH329A. Ports face the rear openings.
// Left end stops short of the brick. sw_x leaves the outside depth at 236 mm,
// with the extra room in front of the switch. The rear wall is the port face.
sw_x = 124.4;  sw_y = 68;  sw_dx = 105;  sw_dy = 158;  sw_h = 26.9;
in_l = sw_x + sw_dx;

// Fuse board, 70 deep x 90 wide, in front of the switch.
// Its right edge lines up with the switch's right edge, the side nearer the wall.
fuse_dx = 70;  fuse_dy = 90;
fuse_x = 12;
fuse_y = sw_y + sw_dy - fuse_dy;

// Screens. Thickness is the bare board, green terminals not included.
// Vigía is the left window. Mission control (cabildo) is the right window.
// The pair is centered, with a short gap between the boards.
// Each opening is the screen itself: 50 x 70 on the left, 106 x 68 on the right.
screen_gap = 36;
pys_w = 50;  pys_h = 70;  pys_t = 6;
kob_w = 106; kob_h = 68;  kob_t = 8;
pys_y = (in_w - pys_w - screen_gap - kob_w) / 2;
kob_y = pys_y + pys_w + screen_gap;
pys_z = 10;
kob_z = pys_z + (pys_h - kob_h) / 2;
kob_win = [0, 0, kob_w, kob_h];    // ox, oz from the board's bottom-left, w, h
pys_win = [0, 0, pys_w, pys_h];

led_w = 45;  led_z = 88;  led_h = 8;
led_y = (in_w - led_w) / 2;
// Shelf behind the slot. The strip drops in from above and the lid keeps it there.
led_shelf_d = 6;     // how far the ledge reaches back into the box
led_shelf_t = 1.8;

// Switch ports begin 6 mm up the case, so the opening starts a little lower.
// A second opening, the same width, sits 9 mm above the first and is 14 mm tall.
sw_slot_y = sw_y;
sw_slot_w = sw_dy;
sw_slot_z = 4;
sw_slot_h = 18;
sw_slot2_h = 14;
sw_slot2_z = sw_slot_z + sw_slot_h + 9;

// Left opening, a little past the brick, so a right-angle mains plug can pass.
// It stops 4 mm short of the switch opening.
plug_extra = 8;
plug_slot_y = brick_y - plug_extra;
plug_slot_w = sw_y - 4 - plug_slot_y;
plug_slot_z = 4;
plug_slot_h = 28;

// Two ALMOCN 5010 fans on the outside of the lid, over the switch, blowing out.
// Frame 50 mm, round opening 45 mm, M3 clearance on a 40 mm pitch.
// 18 mm of plastic between the frames. Nuts sit on the inside of the lid.
fan = 50;
fan_hole = 45;
fan_pitch = 40;
fan_screw = 3.4;
fan_gap = 18;
fan_cx = wall + sw_x + sw_dx / 2;
fan_cy = wall + sw_y + sw_dy / 2;
fan_dy = (fan + fan_gap) / 2;

// Small corners at the switch's two front corners. The rear wall stops the
// back, and the port face stays clear. Everything else is taped down.
corner_th = 1.6;
corner_leg = 8;
corner_h = 4;
slop = 1.2;

$fn = 24;

ow = in_w + 2 * wall;
ol = in_l + 2 * wall;
oh = floor_t + in_h;

// Front face, printed on its own, outer face on the bed.
// A lip in front and a ridge behind form a channel on the floor and
// on both side walls. The face slides down that channel from the top.
slot_fit = lip_fit;
face_t = wall;
face_lip = 1.6;          // ridge in front of the face, keeps it from falling out
rib_t = 2.4;             // ridge behind the face
rib_in = 5;              // how far a side ridge reaches into the box
face_x0 = face_lip + slot_fit / 2;
face_y0 = wall + slot_fit;
face_z0 = floor_t;
face_w = in_w - 2 * slot_fit;
face_h = in_h - slot_fit;
face_x1 = face_x0 + face_t;                 // inside face of the front panel
rib_x = face_x1 + slot_fit / 2;             // ridge just inside the front panel

// Rear face, same channel mirrored. The inside of the panel stays where the
// old wall was, flush with the switch ports. The outer lip adds a little
// length past that so the panel cannot fall out the back.
rear_in = ol - wall;
rear_x0 = rear_in;
rear_x1 = rear_in + face_t;
back_out = rear_x1 + slot_fit / 2 + face_lip;
rear_rib_x1 = rear_in - slot_fit / 2;
rear_rib_x0 = rear_rib_x1 - rib_t;

module tub() {
    difference() {
        cube([back_out, ow, oh]);
        translate([wall, wall, floor_t])
            cube([in_l, in_w, in_h + 1]);

        // mouths the front and rear faces slide into
        translate([-1, wall, floor_t])
            cube([rib_x + 1, in_w, in_h + 1]);
        translate([rear_rib_x1, wall, floor_t])
            cube([back_out - rear_rib_x1 + 1, in_w, in_h + 1]);

        // floor vents under the switch, inset so its edges still sit on plastic
        for (x = [sw_x + 12 : 16 : sw_x + sw_dx - 22])
            for (y = [sw_y + 10 : 14 : sw_y + sw_dy - 16])
                translate([wall + x, wall + y, -1])
                    cube([10, 3, floor_t + 2]);
    }

    face_rails();
    rear_rails();
    switch_corners();
}

module face_rails() {
    // Lip in front of the panel: floor, left wall, right wall.
    translate([0, wall, floor_t])
        cube([face_lip, in_w, rib_in]);
    translate([0, 0, floor_t])
        cube([face_lip, wall + rib_in, in_h]);
    translate([0, ow - wall - rib_in, floor_t])
        cube([face_lip, wall + rib_in, in_h]);

    // Ridge behind the panel. Side ridges stop short of the lid lip.
    ridge_z = in_h - lip_d - slot_fit;
    translate([rib_x, wall, floor_t])
        cube([rib_t, rib_in, ridge_z]);
    translate([rib_x, ow - wall - rib_in, floor_t])
        cube([rib_t, rib_in, ridge_z]);

    translate([rib_x, wall, floor_t])
        cube([rib_t, in_w, rib_in]);
}

// Same channel as the front, on the back wall. The inner floor ridge stays
// under the plug opening and stops short of the switch, whose port face
// is the stop across that stretch.
module rear_rails() {
    translate([back_out - face_lip, wall, floor_t])
        cube([face_lip, in_w, rib_in]);
    translate([back_out - face_lip, 0, floor_t])
        cube([face_lip, wall + rib_in, in_h]);
    translate([back_out - face_lip, ow - wall - rib_in, floor_t])
        cube([face_lip, wall + rib_in, in_h]);

    ridge_z = in_h - lip_d - slot_fit;
    translate([rear_rib_x0, wall, floor_t])
        cube([rib_t, rib_in, ridge_z]);
    translate([rear_rib_x0, ow - wall - rib_in, floor_t])
        cube([rib_t, rib_in, ridge_z]);

    floor_h = plug_slot_z - 0.6;
    for (seg = [[0, sw_y - 1], [sw_y + sw_dy + 1, in_w]])
        translate([rear_rib_x0, wall + seg[0], floor_t])
            cube([rib_t, seg[1] - seg[0], floor_h]);
}

// An L at each front corner of the switch. Legs run along the case,
// outside it by slop, and stop well short of the port face.
module switch_corners() {
    z0 = floor_t - bite;
    zh = corner_h + bite;
    translate([wall + sw_x - slop - corner_th, wall + sw_y - slop - corner_th, z0]) {
        cube([corner_th, corner_leg + corner_th, zh]);
        cube([corner_leg + corner_th, corner_th, zh]);
    }
    translate([wall + sw_x - slop - corner_th, wall + sw_y + sw_dy + slop - corner_leg, z0])
        cube([corner_th, corner_leg + corner_th, zh]);
    translate([wall + sw_x - slop - corner_th, wall + sw_y + sw_dy + slop, z0])
        cube([corner_leg + corner_th, corner_th, zh]);
}

// Ledge just under the LED slot, with a low lip at the back and stops at
// the ends. A short stair under the ledge keeps the overhang printable and
// stays clear of the screen boards below.
module led_shelf() {
    z1 = floor_t + led_z;
    x0 = face_x1 - bite;
    y0 = wall + led_y;
    translate([x0, y0, z1 - led_shelf_t])
        cube([led_shelf_d + bite, led_w, led_shelf_t]);
    translate([x0 + led_shelf_d - 1.6, y0, z1 - led_shelf_t])
        cube([1.6, led_w, led_shelf_t + 3]);
    for (yy = [y0 - 2.4, y0 + led_w])
        translate([x0, yy, z1 - led_shelf_t])
            cube([led_shelf_d + bite, 2.4, led_shelf_t + led_h]);
    for (i = [0 : 0.4 : 2.0])
        translate([x0, y0, z1 - led_shelf_t - 2.4 + i])
            cube([2.8 - i, led_w, 0.41]);
}

// Side cheeks beside the glass, not down to the floor. The fuse board
// sits in front of these screens, so the lower part of the wall is left open.
// A corner shelf still catches the board so it can drop in from above.
module screen_guides(y, z, w, h, t) {
    th = 2.4;
    translate([face_x1 - bite, wall + y - th, floor_t + z])
        cube([t + bite, th, h]);
    translate([face_x1 - bite, wall + y + w, floor_t + z])
        cube([t + bite, th, h]);
    translate([face_x1 - bite, wall + y - th, floor_t + max(z - 2, 0)])
        cube([t + bite, 8, 2]);
    translate([face_x1 - bite, wall + y + w - 8 + th, floor_t + max(z - 2, 0)])
        cube([t + bite, 8, 2]);
}

function ranges_overlap(a0, a1, b0, b1) = a0 < b1 && a1 > b0;

function slot_hits_fan(x, y, w, h) =
    ranges_overlap(x, x + w, fan_cx - fan / 2, fan_cx + fan / 2) &&
    (ranges_overlap(y, y + h, fan_cy - fan_dy - fan / 2, fan_cy - fan_dy + fan / 2) ||
     ranges_overlap(y, y + h, fan_cy + fan_dy - fan / 2, fan_cy + fan_dy + fan / 2));

module fan_open(cy) {
    translate([fan_cx, cy, -1])
        cylinder(d = fan_hole, h = lid_t + 2, $fn = 64);
    for (sx = [-1, 1])
        for (sy = [-1, 1])
            translate([fan_cx + sx * fan_pitch / 2, cy + sy * fan_pitch / 2, -1])
                cylinder(d = fan_screw, h = lid_t + 2);
}

// Outer face on the bed. The lip points up.
module lid_bed() {
    translate([0, ow, lid_t])
        rotate([180, 0, 0])
            lid();
}

module lid() {
    lip_x0 = rib_x;
    lip_y0 = wall + lip_fit;
    lip_dx = rear_rib_x1 - rib_x;
    lip_dy = in_w - 2 * lip_fit;
    difference() {
        union() {
            cube([back_out, ow, lid_t]);
            translate([lip_x0, lip_y0, -lip_d])
                difference() {
                    cube([lip_dx, lip_dy, lip_d]);
                    translate([1.6, 1.6, -1])
                        cube([lip_dx - 3.2, lip_dy - 3.2, lip_d + 2]);
                }
        }
        // vents across the lid, 15 mm clear of every edge.
        // Slots that cross a fan frame are left out. The fans are the outlet
        // over the switch. There is no intake fan.
        vent_m = 15;
        vent_w = 8;
        vent_h = 3;
        for (x = [vent_m : 14 : back_out - vent_m - vent_w])
            for (y = [vent_m : 16 : ow - vent_m - vent_h])
                if (!slot_hits_fan(x, y, vent_w, vent_h))
                    translate([x, y, -1])
                        cube([vent_w, vent_h, lid_t + 2]);
        fan_open(fan_cy - fan_dy);
        fan_open(fan_cy + fan_dy);
        // finger notches
        for (x = [-1, back_out - 5])
            translate([x, ow / 2 - 10, lid_t - 1.2])
                cube([6, 20, 2]);
    }
}

module front_panel() {
    difference() {
        translate([face_x0, face_y0, face_z0])
            cube([face_t, face_w, face_h]);
        translate([face_x0 - 1, wall + kob_y, floor_t + kob_z])
            cube([face_t + 2, kob_w, kob_h]);
        translate([face_x0 - 1, wall + pys_y, floor_t + pys_z])
            cube([face_t + 2, pys_w, pys_h]);
        translate([face_x0 - 1, wall + led_y, floor_t + led_z])
            cube([face_t + 2, led_w, led_h]);
    }
    led_shelf();
    screen_guides(kob_y, kob_z, kob_w, kob_h, kob_t);
    screen_guides(pys_y, pys_z, pys_w, pys_h, pys_t);
}

// Outer face on the bed. The cheeks and the LED ledge point up.
module front_bed() {
    translate([face_h, 0, 0])
        rotate([0, -90, 0])
            translate([-face_x0, -face_y0, -face_z0])
                front_panel();
}

module rear_panel() {
    difference() {
        translate([rear_x0, face_y0, face_z0])
            cube([face_t, face_w, face_h]);
        translate([rear_x0 - 1, wall + sw_slot_y, floor_t + sw_slot_z])
            cube([face_t + 2, sw_slot_w, sw_slot_h]);
        translate([rear_x0 - 1, wall + sw_slot_y, floor_t + sw_slot2_z])
            cube([face_t + 2, sw_slot_w, sw_slot2_h]);
        translate([rear_x0 - 1, wall + plug_slot_y, floor_t + plug_slot_z])
            cube([face_t + 2, plug_slot_w, plug_slot_h]);
    }
}

// Outer face on the bed.
module rear_bed() {
    translate([0, 0, rear_x1])
        rotate([0, 90, 0])
            translate([0, -face_y0, -face_z0])
                rear_panel();
}

// Front and rear, outer face down, with a gap so they print as one plate.
module faces_bed() {
    front_bed();
    translate([face_h + 20, 0, 0]) rear_bed();
}

if (part == "tub" || part == "both") tub();
if (part == "lid") lid_bed();
if (part == "faces") faces_bed();
if (part == "front") front_bed();
if (part == "rear") rear_bed();
if (part == "both") {
    translate([0, ow + 12, lip_d]) lid();
    translate([back_out + 20, 0, 0]) front_bed();
    translate([back_out + 20 + face_h + 20, 0, 0]) rear_bed();
}
