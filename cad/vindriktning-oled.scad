FN=16;

sphereR = 1;
rcWidth = 52;
rCDepth = 46;
rcHeight = 85;
floorThickness = 2;

oledWidth = 33.6979;
oledYOffset = 0.15;
module oled() {
  // size: 33.6979 x 31.8 x 5.2 mm (measured in https://0x00019913.github.io/meshy/)
  rotate([90,0,0])
    // Center an object in the middle of a parent https://stackoverflow.com/a/71715693/4151489
    translate([(rcWidth - oledWidth) / 2,(rCDepth - 31.8),5.25 - rcHeight])
      import("./oled.stl");

}
extraSinkage = 12;
module oledCutout() {
  rotate([90,0,0])
    translate([(rcWidth - (oledWidth + .5)) / 2,(rCDepth - 31.8 - extraSinkage),-rcHeight - .01])
      cube([oledWidth + .5,31.8 + extraSinkage + .01,3]);
}
module oledFrameRails() {
  railWidth = 2;
  railDepth = 1;
  railHeight = 31.9 + extraSinkage;
  module oledFrameRail(xOffset) {
    color("red")
      translate([0,0,-extraSinkage])
        cube([railWidth, railDepth, railHeight - 0.1]);
    color("blue")
      translate([-xOffset,-abs(xOffset) + .01,-extraSinkage])
      cube([railWidth, railDepth , railHeight - 4 ]);
    color("green")
      translate([-(xOffset > 0 ? xOffset : 0), -abs(xOffset) - .75 + .01, -extraSinkage])
        cube([railWidth + abs(xOffset), railDepth, railHeight - 4]);
  }
  // left group of rails
  translate([(rcWidth - (oledWidth + .5)) / 2 - .1, rcHeight - 1, rCDepth - 31.8])
    oledFrameRail(2);
  // right group of rails
  translate([rcWidth - (rcWidth - (oledWidth + .5)) / 2 + .1 - railWidth, rcHeight - 1, rCDepth - 31.8])
    oledFrameRail(-2);
}
//oled();

module floorWallsAndScrewPosts() {
  $fn=FN;
  walls();
  module floor() {
    radius = 2;
    translate([1 + radius,1 + radius,0])
      difference() {
        minkowski() {
          cube([rcWidth - 2 - radius * 2, rcHeight - 2 - radius * 2, floorThickness]);
          sphere(r = radius);
        }
        translate([-radius,-radius,-floorThickness])
          cube([rcWidth + radius,rcHeight + radius,floorThickness]);
        translate([-radius,-radius,floorThickness  ])
          cube([rcWidth + radius,rcHeight + radius,floorThickness]);
      }
  }

  // screw post
  module screwPostOuters(screwPostR = 3, screwPostDistance = 8) {
    translate([screwPostDistance,screwPostDistance,2])
      cylinder(h = 21, r = screwPostR);

    translate([rcWidth - screwPostDistance,screwPostDistance,2])
      cylinder(h = 21, r = screwPostR);

    translate([screwPostDistance,rcHeight - screwPostDistance,2])
        cylinder(h = 21, r = screwPostR);

    translate([rcWidth - screwPostDistance,rcHeight - screwPostDistance,2])
        cylinder(h = 21, r = screwPostR);
  }
  module screwPostInners(screwPostInnerR = 3,  screwPostDistance = 8) {
    screwPostZ = -0.1;
    screwPostHoleR = 1;
    screwPostHoleHeight = 20;
    screwPostInnerHoleHeight = screwPostHoleHeight + 4;
    module screwPostInner1() {
      translate([screwPostDistance,screwPostDistance,screwPostZ])
        cylinder(h = screwPostHoleHeight, r = screwPostInnerR);
      translate([screwPostDistance,screwPostDistance,screwPostZ])
        cylinder(h = screwPostInnerHoleHeight, r = screwPostHoleR);
    }
    module screwPostInner2() {
      translate([rcWidth - screwPostDistance,screwPostDistance,screwPostZ])
        cylinder(h = screwPostHoleHeight, r = screwPostInnerR);
      translate([rcWidth - screwPostDistance,screwPostDistance,screwPostZ])
          cylinder(h = screwPostInnerHoleHeight, r = screwPostHoleR);
    }
    module screwPostInner3() {
      translate([screwPostDistance,rcHeight - screwPostDistance,screwPostZ])
          cylinder(h = screwPostHoleHeight, r = screwPostInnerR);
      translate([screwPostDistance,rcHeight - screwPostDistance,screwPostZ])
          cylinder(h = screwPostInnerHoleHeight, r = screwPostHoleR);
    }
    module screwPostInner4() {
      translate([rcWidth - screwPostDistance,rcHeight - screwPostDistance,screwPostZ])
          cylinder(h = screwPostHoleHeight, r = screwPostInnerR);
      translate([rcWidth - screwPostDistance,rcHeight - screwPostDistance,screwPostZ])
          cylinder(h = screwPostInnerHoleHeight, r = screwPostHoleR);
    }
    // cups at top of screw posts
    cupR = 2.5;
    cupH = 1.1;
    union() {
      screwPostInner1();
      translate([screwPostDistance,screwPostDistance,screwPostInnerHoleHeight-2]) 
        cylinder(h = cupH, r = cupR);
    }
    union() {
      screwPostInner2();
      translate([rcWidth - screwPostDistance,screwPostDistance,screwPostInnerHoleHeight-2]) 
        cylinder(h = cupH, r = cupR);
    }
    union() {
      screwPostInner3();
      translate([screwPostDistance,rcHeight - screwPostDistance,screwPostInnerHoleHeight-2]) 
        cylinder(h = cupH, r = cupR);
    }
    union() {
      screwPostInner4();
      translate([rcWidth - screwPostDistance,rcHeight - screwPostDistance,screwPostInnerHoleHeight-2]) 
        cylinder(h = cupH, r = cupR);
    }
  }
  screwPostR = 3.5;
  screwPostDistance = screwPostR + 3.6;
  screwPostInnerR = 3;
  module floorAndScrewPosts() {
    screwPostOuters(screwPostR, screwPostDistance);
    floor();
  }
  module bottom() {
    difference() {
      floorAndScrewPosts();
      screwPostInners(screwPostInnerR, screwPostDistance);
    }
  }
  bottom();
  // the two posts by the oled frame
  module upperPostSecures() {
    translate([2-.001,rcHeight-9,floorThickness - .001])
      cube([2.5,4,20]);
    translate([rcWidth - 4.5 - .001,rcHeight-9,floorThickness - .001])
      cube([2.5,4,20]);
  }
  upperPostSecures();
  powerCutout();
}

module holes() {
  $fn=FN;
  // holes in floor
  // [start:increment:stop]
  for (i = [80:-4:12]) {
    for (j = [48:-4:4]) {
      if (!(i > 7 * 4 && i < 13 * 4)) {
        // the if is so we don't render the additional hole at the end of the shifted rows
        if (!(i % 8 == 0 && j == 4)
          && !(i == 76 && j == 48)
          && !(i == 76 && j == 44)
          && !(i == 80 && j == 48)
          && !(i == 80 && j == 44)
          && !(i == 76 && j == 4)
          && !(i == 76 && j == 8)
          && !(i == 80 && j == 4)
          && !(i == 80 && j == 8)
          && !(i == 80 && j == 12)
          ) {
          // the ternary is to offset every other row
          translate([(i % 8 == 0) ? j - 2 : j, i,-5])
            cylinder(h = 7.1, r = 1);
        }
      }
    }
  }
}

module innerPowerCutout() {
  $fn=FN;
  minkowski() {
  translate([rcWidth / 2 - 30 / 2 + 1 , -3.001, -1.001])
    cube([28, 10, 26 + 3 + 2]);
    sphere(2);
  }
}

module powerCutout() {
  difference() {
    minkowski() {
    translate([rcWidth / 2 - 30 / 2, 0 - 1.001, 0 - .001])
      cube([30, 10, 27 + 3 + 2]);
      sphere(2);
    }
    innerPowerCutout();
  }
}
module powerCutoutEdges() {
  color("red")
  translate([rcWidth / 2 - 36 / 2, -3, -2]) 
    cube([36, 3, 36]);
  color("blue")
  translate([rcWidth / 2 - 36 / 2, -1, -3]) 
    cube([36, 12.001, 3]);
}

module upperRails() {
  $fn=FN;
  railStartY = 50;
  translate([2,railStartY,2])
    cube([rcWidth - 4, 1, 10]);
  translate([2,railStartY,2])
    cube([3, 1, 24]);
  translate([rcWidth-5,railStartY,2])
    cube([3, 1, 24]);
}
module lowerRails() {
  $fn=FN;
  railStartY = 28;
  translate([2,railStartY,2])
    cube([rcWidth - 4, 1, 3]);
  translate([2,railStartY,2])
    cube([3, 1, 24]);
  translate([rcWidth-5,railStartY,2])
    cube([3, 1, 24]);
}

module usbCPort() {
  translate([(rcWidth - 6) / 2,3.5 + 0.25,25 + 1.75 + 3])
  minkowski() {
    $fn=30;
    cube([6,.001,5]);
    sphere(r = 1.5);
  }
}
module usbPortSupportBlock() {
  s = 1.04;
  color("red")
  difference() {
    translate([(rcWidth - 12) / 2, 4.7, 25 + 1.9 + 3 + 2 + 0.1])
      cube([12,4,4.5]);
    translate([-1.025,.01,-1 + 2])
    scale([s,s,s])
      usbCPort();
  }
}
module usbPortSupportSlider(xOffset) {
  translate([(rcWidth - xOffset) / 2, 1.25, 25 + 1.9 + 3 + 2 + 0.1])
    cube([1,1,8.5]);
}
module usbPortSupportSliders() {
  usbPortSupportSlider(6);
  usbPortSupportSlider(-4);
}

module minkowskiWallsOuter(offset = 0, radius = 5) {
  $fn=45;
  difference() {
    translate([radius + offset / 2,radius + offset / 2,offset / 2])
      minkowski() {
        cube([rcWidth - radius * 2 - offset,rcHeight - radius * 2 - offset,rCDepth]);
        sphere(r = radius);
      }
    if (offset == 0) {
      translate([0,0,-rCDepth + offset / 2])
        cube([rcWidth,rcHeight,rCDepth]);
      translate([0,0,rCDepth - offset / 2])
        cube([rcWidth,rcHeight,rCDepth]);
    } 
  }
}
module walls() {
  difference() {
    minkowskiWallsOuter(0, 5);
    minkowskiWallsOuter(4, 3);
  }
}

module vindriktning() {
  upperRails();
  lowerRails();
  usbPortSupportBlock();
  usbPortSupportSliders();
  difference() {
    floorWallsAndScrewPosts();
    innerPowerCutout();
    powerCutoutEdges();
    usbCPort();
    if (!$preview) {
      holes();
    }
    oledCutout();
  }
  oledFrameRails();
}

vindriktning();  

module powerBoxTest() {
  scaleAmount = 1.1;
  scale([scaleAmount,scaleAmount,scaleAmount])
  translate([0,10,-0.1])
    cube([rcWidth, rcHeight, rCDepth]);
}
module onlyPowerBoxTest() {
  difference() {
    vindriktning();
    powerBoxTest();
  }
}
//!onlyPowerBoxTest();

module oledTest() {
  scaleAmount = 1.1;
  scale([scaleAmount,scaleAmount,scaleAmount])
  translate([0,-15,-0.1])
    cube([rcWidth, rcHeight, rCDepth]);
}
module onlyOledTest() {
  difference() {
    vindriktning();
    oledTest();
  }
}
//!onlyOledTest();

module shim() {
  shimHeight = 11.4;
  lipHeight = 2.6;
  difference() {
    translate([10, 82.35, 33.6979] )
      cube([oledWidth, 1.55, shimHeight]);

    translate([10 - .05, 82.35 - .9, 33.6979 + shimHeight - lipHeight] )
      cube([oledWidth + .1, 1.55, shimHeight]);
  }
}
//!shim();
