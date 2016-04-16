use </usr/lib/openscad/arm_joints.scad>

	$fs = 1;

module fanMount() {

	
	difference() {
		union() {
			hull() {
				cylinder(r = 3, h = 3);
				translate([32, 0, 0]) cylinder(r = 3, h = 3);
			}
			
			cylinder(r = 3, h = 6.3);
			translate([32, 0, 0]) cylinder(r = 3, h = 6.3);
			
			children();
		}
	
		translate([0, 0, -0.01]) cylinder(d = 3.3, h = 6.4);
		translate([32, 0, -0.01]) cylinder(d = 3.3, h = 6.4);
	}
}

module coolerMount() {
	translate([7.3, 15, 3.25]) rotate([-90, 0, 0]) armEnd();
	
	translate([0, 9, 0]) cube([7.3 + 3.25, 6, 3]);
	
	translate([-3, 0, 0]) cube([6, 15, 3]);
}


fanMount()
rotate([0, 0, 90]) coolerMount();
