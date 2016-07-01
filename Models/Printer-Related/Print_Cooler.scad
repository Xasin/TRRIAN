ductHeight = 20;

use </usr/lib/openscad/arm_joints.scad>

module onTag(name) {
	if($tag == name) children();
}

module forNormal() {
	if($tag == "NORMAL") children();
}
	
module forGDiff() {
	if($tag == "GDIFF" || $tag == "NORMAL") children();
}

module buildAssembly() difference() {
	union() {
		build($tag = "NORMAL");
	}
	union() {
		build($tag = "GDIFF");
	}
}

module smoothCube(size, fillet = 5) {
	if(size[0] < fillet*2 || size[1] < fillet*2) echo("WARNING! Cube too small!");
	
	translate([size[0]/2, size[1]/2, 0])
	hull() for(i=[0:180:360]) rotate([0, 0, i]) {
		translate([size[0]/2 - fillet, size[1]/2 - fillet, 0]) cylinder(r = fillet, h = size[2]);
		translate([size[0]/2 - fillet, -size[1]/2 + fillet, 0]) cylinder(r = fillet, h = size[2]);
	}
}

module fanHold() {
	filletSize = 5;
	
	forNormal() {
			hull() for(i=[0:90:360]) rotate([0, 0, i]) translate([21 - filletSize, 21 - filletSize, 0]) cylinder(r = filletSize, h = 7);
	}
				
	forGDiff() {
		for(i=[0:90:360]) rotate([0, 0, i]) translate([16, 16, -0.001]) cylinder(d = 3.2, h = 8, $fn = 9);
		
		translate([0, 0, 1]) cylinder(r = 20, h = 6.5);
	}
}

module airDuct() {
	difference() {
		forNormal() {
			smoothCube([42, 13, ductHeight]);
		}
		
		
		forGDiff() {
			translate([1, 1, -0.01]) smoothCube([40, 11, ductHeight + 10], 4);
		}
	}
}

module build() {
	forNormal() translate([-21, 0, 3.5]) rotate([-90, 0, 90]) armEndRounded();
	
	fanHold();
	rotate([-5, 0, 0]) translate([-21, -21, -ductHeight + 4]) airDuct();
}

buildAssembly();