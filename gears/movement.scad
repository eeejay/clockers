use <parametric_involute_gear_v5.0.scad>;
use <28BYJ.scad>

DEBUG = true;

PRESSURE_ANGLE=28;
CLEARANCE=0.8;
DISTANCE_ADJUST=0.1;

$fn = 100;
INCH = 25.4;
TAP_SIZE = 3.35;
GEAR_THICKNESS = 0.125*INCH;
SUPPORT_DIAMETER = TAP_SIZE + 3;
ENDGEAR_HEIGHT = 0.25*INCH;
GEARBOX_HEIGHT = 1*INCH;
SPIN = 0.65;
FIT = 0.35;
PITCH = 16;
SUPPORT_THICKNESS = 2;

MOTOR_GEAR_HEIGHT = ENDGEAR_HEIGHT*2 + SUPPORT_THICKNESS;

HOUR_ANGLE = 0;
HOUR_DIAMETER = 0.375*INCH;
HOUR_GEARS = [[20,20], [20, 10]]; // 2:1
HOUR_AXLE_HEIGHT = 0.25*INCH + 8;

MINUTE_ANGLE = 90;
MINUTE_DIAMETER = 0.25*INCH;
MINUTE_GEARS = [[20,20], [20, 10]]; // 2:1
MINUTE_AXLE_HEIGHT = 0.75*INCH + 8;

SECOND_ANGLE = 180;
SECOND_DIAMETER = TAP_SIZE;
SECOND_GEARS = [[20,20], [20, 10]]; // 2:1
SECOND_AXLE_HEIGHT = 0;

function inch(x) = x*INCH;

module _handgrip(outerd, innerd, h=8) {
  union() {
    translate([0,0,1]) cylinder(r=(outerd + FIT/2)/2, h=h);
    translate([0,0,-h]) cylinder(r=(innerd + SPIN)/2, h=h*2);
  }
}

module handgrip(handname) {
  if (handname == "hour") {
    _handgrip(HOUR_DIAMETER, MINUTE_DIAMETER);
  }
  if (handname == "minute") {
    echo("HI");
    _handgrip(MINUTE_DIAMETER, SECOND_DIAMETER);
  }
  if (handname == "second") {
    _handgrip(SECOND_DIAMETER, 0);
  }
}

module stackedgear(t1, t2, extra_height=0) {
  h = GEARBOX_HEIGHT-GEAR_THICKNESS*2+SUPPORT_THICKNESS/2;
  gt = extra_height > GEAR_THICKNESS ? GEAR_THICKNESS : GEAR_THICKNESS * 2 + extra_height;
  difference() {
    union() {
      translate([0,0,h + (gt == GEAR_THICKNESS ? 0 : -GEAR_THICKNESS - extra_height)]) gear(diametral_pitch=PITCH/INCH, number_of_teeth=t1, circles=(t1 >= 40 ? 6 : 0),
        rim_thickness=gt+SPIN, rim_width=2.5, hub_thickness=0, gear_thickness=gt,
        pressure_angle=PRESSURE_ANGLE, clearance = CLEARANCE, bore_diameter=SUPPORT_DIAMETER + SPIN, backlash=0);
        translate([0,0,SUPPORT_THICKNESS+FIT/2]) cylinder(r=geardistance(t1,t1)/2-7,h=GEARBOX_HEIGHT - SUPPORT_THICKNESS*2 - FIT);
    }
    translate([0,0,GEARBOX_HEIGHT-GEAR_THICKNESS+SPIN+FIT-2]) {
      translate([0,-9,0]) cylinder(h=20, r=1.575);
      translate([0,9,0]) cylinder(h=20, r=1.575);
    }
    cylinder(r=(SUPPORT_DIAMETER + SPIN)/2,h=GEARBOX_HEIGHT);
  }
  if (gt == GEAR_THICKNESS)
    translate([0,0,h-extra_height-GEAR_THICKNESS]) gear(diametral_pitch=PITCH/INCH, number_of_teeth=t1, circles=(t1 >= 40 ? 6 : 0),
      rim_thickness=GEAR_THICKNESS, rim_width=2.5, hub_thickness=0, gear_thickness=GEAR_THICKNESS,
      pressure_angle=PRESSURE_ANGLE, clearance = CLEARANCE, bore_diameter=SUPPORT_DIAMETER + SPIN, backlash=0);
}

module endgear(number_of_teeth, bore_diameter, terminator_diameter, axle_height) {
  translate([0,0,ENDGEAR_HEIGHT]) rotate([0,180,0]) difference() {
    union() {
      gear(diametral_pitch=PITCH/INCH, number_of_teeth=number_of_teeth, circles=(number_of_teeth >= 40 ? 6 : 0),
        rim_thickness=GEAR_THICKNESS, hub_thickness=ENDGEAR_HEIGHT, gear_thickness=GEAR_THICKNESS,
        pressure_angle=PRESSURE_ANGLE, clearance = CLEARANCE, bore_diameter=bore_diameter, backlash=0,  hub_diameter=15);

      if (axle_height > 0)
        translate([0,0,0.125*INCH])  cylinder(h=axle_height, r=terminator_diameter/2);
    }
    cylinder(r=bore_diameter/2, h=100);
    if (terminator_diameter < 0) {
      translate([0,0,GEAR_THICKNESS*2-4.5]) cylinder(r=4.5, h=5, $fn=6);
    }
  }
}

module startgear(number_of_teeth=0) {
  hub_thickness = GEAR_THICKNESS;
  difference() {
    if (number_of_teeth > 0) {
     translate([0,0,hub_thickness]) rotate([0,180,0]) gear(diametral_pitch=PITCH/INCH, number_of_teeth=number_of_teeth, circles=0,
      rim_thickness=GEAR_THICKNESS+1, hub_thickness=hub_thickness, gear_thickness=GEAR_THICKNESS-1.5, rim_width=2.5,
      pressure_angle=PRESSURE_ANGLE, clearance = CLEARANCE, bore_diameter=0, backlash=0,  hub_diameter=5);
    } else {
      // debug
      cylinder(r=7.5,h=hub_thickness);
    }
    intersection() {
      translate([0,0,-0.5]) cylinder(r=2.5,h=hub_thickness+1);
      union() {
        translate([0,0,0]) cube([3,6,hub_thickness*2+1], center = true);
        translate([0,0,-2]) cube([6,6,6], center = true);
      }
    }

  }
}

function geardistance(teeth1,teeth2) = (teeth1 && teeth2) ?
  ((teeth1+teeth2)/(PITCH*2))*INCH + DISTANCE_ADJUST : 0;

function armlength(gears, index=0, total=0) =
  gears[index] ?
    armlength(gears, index+1, total + geardistance(gears[index][1], gears[index][0])) : total;

function gearcenters(gears, index=0, total=0) =
  gears[index]
  ? concat(geardistance(gears[index][1], gears[index][0]) + total, gearcenters(gears, index+1, total+geardistance(gears[index][1], gears[index][0])))
  : [];

function sascalc(s1, a, s2) = sqrt(pow(s1,2) + pow(s2,2) - 2*s1*s2*cos(a));
function ssscalc(s1,s2,s3) = acos((pow(s1,2) + pow(s2,2) - pow(s3,2))/(2*s1*s2));

module gearset(gears, end_bore, end_terminator, axle_height, elevation, index=0, print=false) {
  gear1 = gears[index - 1][1];
  gear2 = gears[index][0];
  offsetX = print ? geardistance(gears[index][1], gear2) + 5 : geardistance(gears[index][1], gear2);
  if (!gear1 && gear2) {
    // this is the first "end-gear"
    printRotate = print ? 180 : 0;
    printTranslate = print ? -ENDGEAR_HEIGHT : SUPPORT_THICKNESS+elevation;
    rotate([printRotate,0,0]) translate([0,0,printTranslate]) endgear(gear2, end_bore, end_terminator, axle_height);
    translate([offsetX,0,ENDGEAR_HEIGHT - GEAR_THICKNESS*2]) gearset(gears, 0, 0, axle_height, elevation, index+1, print);
  } else if (gear1 && gear2) {
    extraHeight = !gears[index+1] ? MOTOR_GEAR_HEIGHT - elevation : 0;
    printTranslate = print ? GEAR_THICKNESS - ENDGEAR_HEIGHT : SUPPORT_THICKNESS+elevation;
    translate([0,0,GEAR_THICKNESS - SPIN]) stackedgear(print ? gear2 : gear1, print ? gear1 : gear2, extraHeight);
    translate([offsetX,0,0]) gearset(gears, 0, 0, axle_height, elevation, index+1, print);
  } else if (gear1 && !gear2) {
    printRotate = print ? 180 : 0;
    printTranslate = print ? -GEAR_THICKNESS: SUPPORT_THICKNESS+GEAR_THICKNESS*2+MOTOR_GEAR_HEIGHT;
    rotate([printRotate,0,0]) translate([0,0,printTranslate]) startgear(gear1);
  }
}

module screwholes(gears, index=0) {
  offsetX = geardistance(gears[index][1], gears[index][0]);
  if (gears[index]) {
    if (gears[index+1]) {
      if (offsetX) {
        translate([offsetX,0,0]) {
          translate([0,0,-0.5]) cylinder(h=GEARBOX_HEIGHT+SUPPORT_THICKNESS*2 + 1, r=(TAP_SIZE+SPIN)/2);
          screwholes(gears, index+1);
        }
      }
    } else {
      // Remake motor mount hole (bottom)
      translate([offsetX + 8, 0, 1]) cylinder(h=SUPPORT_THICKNESS, r=14.25);
      // Motor shaft hole (top)
      translate([offsetX, 0, GEARBOX_HEIGHT]) cylinder(h=SUPPORT_THICKNESS*3, r=2.5+SPIN/2);
    }
  }
}

module motormount() {
  difference() {
    union() {
      cylinder(h=SUPPORT_THICKNESS, r=16);
      translate([(SUPPORT_DIAMETER+4)/-2,-17.5,0]) cube([SUPPORT_DIAMETER+4,35,2]);
      translate([0,-17.5,0]) {
        cylinder(h=SUPPORT_THICKNESS, r=(SUPPORT_DIAMETER+4)/2);
        cylinder(h=19, r=(SUPPORT_DIAMETER+2)/2);
      }
      translate([0,17.5,0]) {
        cylinder(h=SUPPORT_THICKNESS, r=(SUPPORT_DIAMETER+4)/2);
        cylinder(h=19, r=(SUPPORT_DIAMETER+2)/2);
      }
    }
    translate([0,-17.5, -1]) cylinder(h=21, r=(TAP_SIZE+SPIN)/2);
    translate([0,17.5, -1]) cylinder(h=21, r=(TAP_SIZE+SPIN)/2);
    translate([0,0,1]) cylinder(h=SUPPORT_THICKNESS, r=14);
  }
  %translate([0,0,10.5]) rotate([0,180,0]) StepMotor28BYJ();
}

module motormounttop() {
  difference() {
    union() {
      cylinder(h=SUPPORT_THICKNESS, r=16);
      translate([(SUPPORT_DIAMETER+4)/-2,-17.5,0]) cube([SUPPORT_DIAMETER+4,35,2]);
      translate([0,-17.5,0]) {
        cylinder(h=SUPPORT_THICKNESS, r=(SUPPORT_DIAMETER+4)/2);
        translate([0,0,-7.5]) cylinder(h=7.5+SUPPORT_THICKNESS, r=(SUPPORT_DIAMETER+2)/2);
      }
      translate([0,17.5,0]) {
        cylinder(h=SUPPORT_THICKNESS, r=(SUPPORT_DIAMETER+4)/2);
        translate([0,0,-7.5]) cylinder(h=7.5+SUPPORT_THICKNESS, r=(SUPPORT_DIAMETER+2)/2);
      }
    }
    translate([0,-17.5, -8]) cylinder(h=20, r=(TAP_SIZE+SPIN)/2);
    translate([0,17.5, -8]) cylinder(h=20, r=(TAP_SIZE+SPIN)/2);
  }
}

module bottomsupport(gears, elevation, index=0, totalOffsetX=0) {
  offsetX = geardistance(gears[index][1], gears[index][0]);

  if (gears[index]) {
    if (totalOffsetX) {
      h = SUPPORT_THICKNESS+(ENDGEAR_HEIGHT - GEAR_THICKNESS);
      translate([totalOffsetX,0,0]) {
        cylinder(h=h-SPIN, r=SUPPORT_DIAMETER);
        column_height = GEARBOX_HEIGHT/2 + SUPPORT_THICKNESS;
        cylinder(h=column_height, r=SUPPORT_DIAMETER/2);
      }
    }
    difference() {
      union() {
        bottomsupport(gears, elevation, index+1, totalOffsetX=totalOffsetX+offsetX);
      }
      if (index == 0) screwholes(gears);
    }
  } else {
    translate([0, (SUPPORT_DIAMETER+4)/-2, 0]) cube([totalOffsetX, SUPPORT_DIAMETER+4, SUPPORT_THICKNESS]);
    translate([totalOffsetX + 8, 0, 0]) motormount();
  }
}

module topsupport(gears, elevation, index=0, totalOffsetX=0) {
  offsetX = geardistance(gears[index][1], gears[index][0]);

  if (totalOffsetX) {
    h = (gears[index+1]) ?
      GEARBOX_HEIGHT + SUPPORT_THICKNESS - ENDGEAR_HEIGHT - elevation - GEAR_THICKNESS:
      GEARBOX_HEIGHT + SUPPORT_THICKNESS - ENDGEAR_HEIGHT - MOTOR_GEAR_HEIGHT - GEAR_THICKNESS;
    translate([totalOffsetX,0,GEARBOX_HEIGHT + SUPPORT_THICKNESS*2]) {
      translate([0,0,-h]) cylinder(h=h, r=gears[index] ? SUPPORT_DIAMETER : 5);
      if (index==1) {
        column_height = elevation + SUPPORT_THICKNESS > GEARBOX_HEIGHT/2 ?
          GEAR_THICKNESS*3 + SUPPORT_THICKNESS +1 : GEARBOX_HEIGHT/2 + SUPPORT_THICKNESS;
        translate([0,0,-column_height]) cylinder(h=column_height, r=SUPPORT_DIAMETER/2);
      }
    }
  }

  if (gears[index]) {
    difference() {
      topsupport(gears, elevation, index+1, totalOffsetX=totalOffsetX+offsetX);
      if (index == 0) screwholes(gears);
    }
  } else {
    translate([0, 0, GEARBOX_HEIGHT+SUPPORT_THICKNESS]) {
      translate([0,(SUPPORT_DIAMETER+4)/-2,0]) cube([totalOffsetX, SUPPORT_DIAMETER+4, SUPPORT_THICKNESS]);
      translate([totalOffsetX,0,0]) cylinder(h=SUPPORT_THICKNESS, r=SUPPORT_DIAMETER);
      translate([totalOffsetX + 8, 0, 0]) motormounttop();
    }
  }
}

module geardrive(gears, end_bore, end_terminator, axle_height, elevation, rotation, do=["top", "bottom", "gears"], print=false) {
  rotate([0,0,rotation]) {
    if (search(["gears"], do)[0] != [])
      gearset(gears, end_bore, end_terminator, axle_height, elevation, 0, print);
    if (search(["bottom"], do)[0] != [])
      bottomsupport(gears, elevation);
    if (search(["top"], do)[0] != [])
      topsupport(gears, elevation);
  }
}

module gearbox(do=["top", "bottom", "gears"], hand=["hour", "minute", "second"], print=false) {
  if (search(["hour"], hand)[0] != [])
    geardrive(HOUR_GEARS, MINUTE_DIAMETER + SPIN, HOUR_DIAMETER, HOUR_AXLE_HEIGHT, 0, HOUR_ANGLE, do=do, print=print);
  if (search(["minute"], hand)[0] != [])
    geardrive(MINUTE_GEARS, SECOND_DIAMETER + SPIN, MINUTE_DIAMETER, MINUTE_AXLE_HEIGHT, ENDGEAR_HEIGHT, MINUTE_ANGLE, do=do, print=print);
  if (search(["second"], hand)[0] != [])
    geardrive(SECOND_GEARS, SECOND_DIAMETER, 0, SECOND_AXLE_HEIGHT, ENDGEAR_HEIGHT*2, SECOND_ANGLE, do=do, print=print);
}

module struts(s1, a, s2, top=false) {
  s3 = sascalc(s1, a, s2);
  angle = ssscalc(s1, s3, s2);
  offsetY = top ? - GEARBOX_HEIGHT/2 : SUPPORT_THICKNESS;
  difference () {
    union() {
      translate([s1,0,0])
        rotate([0,0,90-angle]) translate([-(SUPPORT_DIAMETER+4)/2,0,0])
          cube([SUPPORT_DIAMETER+4, s3 ,SUPPORT_THICKNESS]);
      rotate([0,0,a/2]) translate([sqrt(pow(s1,2) - pow(s3/2,2)),0,offsetY]) cylinder(r=SUPPORT_DIAMETER/2, h=GEARBOX_HEIGHT/2);
    }
    rotate([0,0,a/2]) translate([sqrt(pow(s1,2) - pow(s3/2,2)),0,offsetY-0.5-SUPPORT_THICKNESS]) cylinder(r=(TAP_SIZE+SPIN)/2, h=GEARBOX_HEIGHT);
  }
}

module bottombracket(print=false) {
  difference() {
    union() {
      gearbox(do=["bottom"]);
      cylinder(h=SUPPORT_THICKNESS+2, r=(18+SPIN)/2);
      struts(armlength(HOUR_GEARS), MINUTE_ANGLE, armlength(MINUTE_GEARS));
      rotate([0,0,MINUTE_ANGLE]) struts(armlength(MINUTE_GEARS), SECOND_ANGLE - MINUTE_ANGLE, armlength(SECOND_GEARS));

    }
    for (elem = [[armlength(HOUR_GEARS), HOUR_ANGLE],
                 [armlength(MINUTE_GEARS), MINUTE_ANGLE],
                 [armlength(SECOND_GEARS), SECOND_ANGLE]]) {
      // Remake motor mount hole (bottom)
      rotate([0,0,elem[1]]) translate([elem[0] + 8, 0, 1]) cylinder(h=19, r=14.25);
    }
    translate([0,0,SUPPORT_THICKNESS]) cylinder(h=SUPPORT_THICKNESS+2, r=(15+SPIN)/2);
    translate([0,0,-1]) cylinder(h=SUPPORT_THICKNESS+2, r=(HOUR_DIAMETER+SPIN)/2);
  }

}

module topbracket(print=false) {
  totranslate = print ? GEARBOX_HEIGHT+SUPPORT_THICKNESS*2 : 0;
  torotate = print ? 180 : 0;
   translate([0,0,totranslate]) rotate([torotate,0,0]) difference() {
    union() {
      gearbox(do=["top"]);
      translate([0,0,GEARBOX_HEIGHT+SUPPORT_THICKNESS]) {
        h = GEARBOX_HEIGHT - ENDGEAR_HEIGHT*3 + SUPPORT_THICKNESS;
        translate([0,0,-h+SUPPORT_THICKNESS]) cylinder(h=h, r=5);

        struts(armlength(HOUR_GEARS), MINUTE_ANGLE, armlength(MINUTE_GEARS), true);
        rotate([0,0,MINUTE_ANGLE]) struts(armlength(MINUTE_GEARS), SECOND_ANGLE - MINUTE_ANGLE, armlength(SECOND_GEARS), true);
      }
    }
    translate([0,0,GEARBOX_HEIGHT/2]) cylinder(h=GEARBOX_HEIGHT, r=(SECOND_DIAMETER+SPIN)/2);
    for (elem = [[armlength(HOUR_GEARS), HOUR_ANGLE],
                 [armlength(MINUTE_GEARS), MINUTE_ANGLE],
                 [armlength(SECOND_GEARS), SECOND_ANGLE]]) {
      // Motor shaft hole (top)
      rotate([0,0,elem[1]]) translate([elem[0], 0, GEARBOX_HEIGHT]) cylinder(h=SUPPORT_THICKNESS*3, r=2.5+SPIN/2);
    }
  }
}

//topbracket();
//gearbox(do=["gears"]);
bottombracket();

/*
geardrive(HOUR_GEARS, MINUTE_DIAMETER + SPIN, HOUR_DIAMETER + FIT, 0, HOUR_ANGLE);
geardrive(MINUTE_GEARS, SECOND_DIAMETER + SPIN, MINUTE_DIAMETER + FIT, ENDGEAR_HEIGHT, MINUTE_ANGLE);
geardrive(SECOND_GEARS, 0, SECOND_DIAMETER + FIT, ENDGEAR_HEIGHT*2, SECOND_ANGLE);
*/
