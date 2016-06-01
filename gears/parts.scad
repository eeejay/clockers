use <movement.scad>
use <sensorclamp.scad>
use <boardmounts.scad>

INCH = 25.4;

if (mode == "hourgears") {
  gearbox(do=["gears"], hand=["hour"], print=true);
}

if (mode == "minutegears") {
  gearbox(do=["gears"], hand=["minute"], print=true);
}

if (mode == "secondgears") {
  gearbox(do=["gears"], hand=["second"], print=true);
}

if (mode == "bottombracket") {
  bottombracket(print=true);
}

if (mode == "topbracket") {
  topbracket(print=true);
}

if (mode == "sensorclamps") {
  sensorclamps();
}

if (mode == "pimount") {
  pimount();
}

if (mode == "motordriversmount") {
  motordriversmount();
}

// SVGs

mode = "rearlayout";

module rearlayout() {
  topbracket();
  gearbox(do=["gears"]);
  bottombracket();
  difference() {
    cylinder(r=6*25.4+1, h=0.5, $fn=100);
    translate([0,0,-0.25]) cylinder(r=6*25.4, h=1, $fn=100);
  }

  translate([0,-40,0]) motordriversmount();

  translate([21.9,-98.8,0]) pimount();
}

if (mode == "rearlayout") {
  rearlayout();
}

if (mode == "rearlayoutsvg") {
  projection(cut=false) rearlayout();
}
