use </usr/lib/openscad/arm_joints.scad>

	$fs = 0.8;

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

module mountPin() {
	cylinder(r = 3.5, h =2);
	translate([0, -3.5, 0]) cube([3.5, 7, 2]);
}	

module fanConnector() {
	difference() {
		translate([-14/2, -3.5, 3.5]) rotate([0, 90, 0]) {	
			mountPin();
			translate([0, 0, 12]) mountPin();
		}
		
		translate([-50, -3.5, 3.5]) rotate([0, 90, 0]) cylinder(r = 3.4/2, h = 100);
	}
}


module coolerMount() {
	headXTranslate = 13;
	headYTranslate = 12;
	
	translate([headYTranslate, headXTranslate + 6.99, 0]) fanConnector();
	
	translate([0, headXTranslate - 6, 0]) cube([headYTranslate + 7, 6, 3]);
	
	translate([-3, 0, 0]) cube([6, headXTranslate, 3]);
}


fanMount()
rotate([0, 0, 90]) coolerMount();

