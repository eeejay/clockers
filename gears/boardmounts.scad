$fn=100;

module _square(width, height) {
  translate([width/2,height/2,0]) children();
  translate([-width/2,-height/2,0]) children();
  translate([width/2,-height/2,0]) children();
  translate([-width/2,height/2,0]) children();
}

module bracket(width, height) {
  difference() {
    union() {
      _square(width, height) {
        cylinder(r=4.5, h=5);
        cylinder(r=3, h=10);
      }
      difference() {
        translate([0,0,1]) cube([width+2,height+2,2], center=true);
        cube([width-4,height-4,5], center=true);
      }
    }
    _square(width, height) translate([0, 0,-1]) {
      cylinder(r=2, h=12);
      cylinder(r=4, h=4, $fn=6);
    }
  }
}

module _facemount(distance) {
  difference() {
    hull() {
      translate([distance,0,0]) cylinder(r=5,h=2);
      translate([-distance,0,0]) cylinder(r=5,h=2);
    }
    translate([distance,0,-1]) cylinder(r=2,h=4);
    translate([-distance,0,-1]) cylinder(r=2,h=4);
  }
}


module motordriversmount() {
  for (i=[-1:1])
    translate([33.5*i,0,0]) bracket(25, 30);
  _facemount(55);
}

module pimount(width=58, height=49) {
  difference() {
    union()  {
      _square(width, height) {
        cylinder(r=3.5, h=3);
      }
      difference() {
        translate([0,0,1]) cube([width+2,height+2,2], center=true);
        cube([width-4,height-4,5], center=true);
      }
    }
    _square(width, height) translate([0, 0,-1]) {
      cylinder(r=2, h=12);
    }
  }
}

module perfmount() {
  union() {
    bracket(57, 74);
    _facemount(35);
  }
}

motordriversmount();
