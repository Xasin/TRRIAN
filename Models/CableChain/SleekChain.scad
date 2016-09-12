function aPoint(a) = [-sin(dToR(a)), cos(dToR(a))];
function dToR(a) = a * 0.017453;


$fs = 1;
$fa = 5;

// Diameter of the click-axis (for click-together type chains)
clickAxisDiameter = 3;

// Diameter of the filament (for Fila-Axis type chains)
filamentDiameter = 1.75;


module maleConnector_disk(a1, r, h = 1, a2 = 0) {
	$fs = 0.1;
	linear_extrude(height = h) {
		intersection() {
			union() {
				circle(r = r);
				rotate(a2) square([r, r]);
				rotate(90 + a1) square([r, r]);
				translate([-r, -r]) square([2*r, r]);
			}
			translate([-r, -r]) square([2*r, 2*r]);
		}
	}
}

module maleConnector_filaAxis(a1, r, h = 1, a2 = 0) {
	difference() {
		maleConnector_disk(a1, r, h, a2);
		translate([0, 0, -0.1]) cylinder(d = filamentDiameter + 0.2, h = h + 1, $fn = 13);
	}
}

module maleConnector_clickAxis(a1, r, h = 1, a2 = 0) {
	difference() {
		maleConnector_disk(a1, r, h, a2);
		translate([0, 0, -0.1]) cylinder(d = clickAxisDiameter + 0.2, h = h + 1, $fn = 13);
		translate([-clickAxisDiameter/2, 0, -0.1]) cube([clickAxisDiameter, r + 1, 0.3]);
	}
}
	
maleConnector_clickAxis(45, 5);
				