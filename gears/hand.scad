$fn = 100;

use <movement.scad>

SIZE = inch(10.75);

module makeShape(hand) {
  intersection() {
    translate([-SIZE/2,-SIZE/2,0]) linear_extrude(height = 2, convexity = 10)
      resize([SIZE,SIZE,1]) import (file = str(hand, "_hand.dxf"));
    cube([SIZE-30,SIZE-30,SIZE-30], center=true);
  }
}

module makeHand(hand) {
  if (hand == "second") {
    difference() {
      union() {
        makeShape(hand);
        translate([0,0,1]) cylinder(r=(SECOND_DIAMETER+1.25)/2, h=6);
      }
      translate([0,0,3]) cylinder(r=SECOND_DIAMETER/2, h=20);
    }
  } else {
    diam = hand == "minute" ? 8 : 10;
    elev = hand == "minute" ? 2 : 1;
    difference() {
      union() {
        makeShape(hand);
        cylinder(r=diam/2+1, h=5);
      }
      handgrip(hand);
    }
  }
}

dohand = "hour";

makeHand(dohand);
