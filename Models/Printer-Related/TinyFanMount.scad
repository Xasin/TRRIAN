
use <TagSystem/Tagging.scad>

$fs = 0.4;

mountHoleDist = 24;
gClearance = 35;

fanMHoleDist = 20;
fanMHoleSize = 2.5;
fanWidth = 25;

module mount_hole(hDiam = 3) {
	taggedDifference("2positive", "negative", "positive", true) {
		tag("2positive") circle(d = hDiam + 1*2);
		tag("negative") circle(d = hDiam + 0.2);
	}
}

module mount_holes(hDiam = 3, dist = mountHoleDist) {
	translate([dist/2, 0, 0]) mount_hole(hDiam);
	translate([-dist/2, 0, 0]) mount_hole(hDiam);
}

module extr_mount_holes() mount_holes(3, mountHoleDist);

module fan_mount_holes() 
translate([mountHoleDist/2 - 7, fanWidth/2 + fanMHoleDist/2 - gClearance]) mount_holes(fanMHoleSize, fanMHoleDist);

module holes() {
	extr_mount_holes();
	fan_mount_holes();
}

module fan_mount() linear_extrude(height = 2) {
	
	difference() {
		hull() {
			holes();
		}
		showTag("negative") holes();
	}
}

fan_mount();