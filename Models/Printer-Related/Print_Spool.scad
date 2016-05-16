
heightEdge = 0.8;

spoolTotalHeight = 75;
spoolCylinderOuterRadius = 5;

spoolCylinderHeight = heightEdge * 2 + spoolTotalHeight;


SCMountHeight = 20;
SCMountThickness = 2;
SCMountDistance = 100;

filamentAxisDepth = 15;

$fs = 0.8;

module edgedCylinder(r = 10, ri, he = heightEdge, h = 10) {
	ri = (ri == undef ? r - 1.2 : ri);
	cylinder(r1 = r, r2 = ri, h = he);
	translate([0, 0, he]) cylinder(r = ri, h = h - 2*he);
	translate([0, 0, h - he]) cylinder(r1 = ri, r2 = r, h = he);
}

module spoolCylinder() {
	difference() {
		union() {
			edgedCylinder(r = spoolCylinderOuterRadius, h = heightEdge * 2 + 6);
			translate([0, 0, heightEdge * 2 + 6]) edgedCylinder(r = spoolCylinderOuterRadius, h = spoolTotalHeight - 6);
		}
		
		translate([0, 0, -0.1]) cylinder(d = 4, h = filamentAxisDepth);
		translate([0, 0, spoolCylinderHeight - filamentAxisDepth]) cylinder(d = 4, h = 100);
	}
}

module SCMount() {
	translate([0, 0, SCMountHeight]) rotate([0, 90, 0]) difference() {
		union() {
			cylinder(r = spoolCylinderOuterRadius, h = SCMountThickness);
			translate([0, -spoolCylinderOuterRadius, 0]) cube([SCMountHeight, spoolCylinderOuterRadius*2, SCMountThickness]);
		}
		
		translate([0, 0, -0.1]) cylinder(d = 3.5, h = 10);
	}
}

module SCMounts() {
	translate([0, spoolCylinderOuterRadius, -0.001]) {
		SCMount();
		translate([SCMountThickness + spoolCylinderHeight, 0, 0]) SCMount();
		
		translate([0, SCMountDistance, 0]) SCMount();
		translate([SCMountThickness + spoolCylinderHeight, SCMountDistance, 0]) SCMount();
	}
}

module SCBase() {
	SCMounts();
	translate([spoolCylinderHeight/2 - 15/2, -30, -2]) FilamentGuide();
	
	difference() {
		translate([0, 0, -2]) cube([SCMountThickness*2 + spoolCylinderHeight, SCMountDistance + 2*spoolCylinderOuterRadius, 2]);
		translate([spoolCylinderOuterRadius*2, spoolCylinderOuterRadius*2, -3]) cube([SCMountThickness*2 + spoolCylinderHeight - spoolCylinderOuterRadius*4, SCMountDistance - spoolCylinderOuterRadius*2, 10]);
	}
}

module FilamentGuide() {
	cube([15, 30, 2]);
	difference() {
		cube([15, 2, 20]);
		translate([15/2, 5, 20 - 15/2]) #rotate([90, 0, 0]) cylinder(d = 4, h = 10);
	}
}

spoolCylinder();