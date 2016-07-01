
hullHeight = 1.5;

$fs = 1;

module smoothSquare(size = 20, filletSize = 4) {
	hull() {
		for(i=[0:90:360]) rotate([0, 0, i]) translate([size - filletSize, size - filletSize]) circle(r = filletSize);
	}
}

module mountHoles() {
	difference() {
		union() {
			for(i=[0:90:90]) rotate([0, 0, i]) translate([16, 16, 0]) cylinder(d = 3.3 + 1.5 * 2, h = 1);
			children();
		}
		
		for(i=[0:90:90]) rotate([0, 0, i]) translate([16, 16, 0]) {
			cylinder(d = 3.3, h = 5);
			translate([0, 0, 1]) cylinder(d = 5.5, h = 5);
		}
	}
}
		

module carryHull() {
	linear_extrude(height = hullHeight, convexity = 3) difference() {
		smoothSquare(20, 4); 
		smoothSquare(18, 3);
	}
}

module slice(angle = 10) {
	polygon([[0, 0], [100, 0], [100, tan(angle) * 100]]);
}

module airBlocker() {
	
	block = 0.5;
	
	linear_extrude(height = 0.40, convexity = 2) {
		difference() {
				smoothSquare(18, 0.5);
				
			
			for(i=[0:12]) rotate([0, 0, 360/12 * i - 20]) slice(angle = 360/12 * block);
			}
			
			circle(r = 5);
	}
}

mountHoles()
union() {
	carryHull();
	airBlocker();
}