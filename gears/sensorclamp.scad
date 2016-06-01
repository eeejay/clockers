$fn=100;
TAP_SIZE = 3.7;
LENGTH=28;

module sensorclamp() {
  difference() {
    hull() {
      translate([0,LENGTH/2,0]) cylinder(h=5, r=TAP_SIZE);
      translate([0,-LENGTH/2,0]) cylinder(h=5, r=TAP_SIZE);
    }
    translate([0,-LENGTH/2,-1]) cylinder(h=7, r=TAP_SIZE/2);
    translate([-7.5,LENGTH/2-8,-3]) cube([15,10,5]);
    translate([-7.5,LENGTH/2-8-10,-4]) cube([15,10,5]);
  }
}

module sensorclamps() {
  rotate([0,180,0]) {
    translate([0,0,-5]) sensorclamp();
    translate([10,0,-5]) sensorclamp();
    translate([-10,0,-5]) sensorclamp();
  }
}

sensorclamps();
