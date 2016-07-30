include <Values.scad>

wallThickness = 1.3;

clipHeight = 2;

clipClipLength = 1.7;

innerClipWidth = chainLinkWidth + 4*connectorThickness;
outerClipWidth = innerClipWidth + 2*wallThickness;

innerClipHeight = connectorRadius * 2 + 2.5*clearing;
outerClipHeight = innerClipHeight + 2*wallThickness;

module CableClip() {
  difference() {
    cube([outerClipWidth, outerClipHeight, clipHeight]);
    translate([wallThickness, wallThickness, -0.1]) cube([innerClipWidth, innerClipHeight, clipHeight + 0.2]);

    translate([wallThickness + clipClipLength, -0.001, -0.1])
	cube([innerClipWidth - 2*clipClipLength, innerClipHeight + wallThickness, clipHeight + 0.2]);
  }
}

CableClip();
