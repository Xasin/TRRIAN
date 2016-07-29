include <Values.scad>

module maleConnector_disk() {
	$fs = 0.1;
	linear_extrude(height = connectorThickness) {
		intersection() {
			union() {
				circle(r = $cRadius);
				rotate(-$angle2) square([$cRadius, $cRadius]);
				rotate(90 + $angle1) square([$cRadius, $cRadius]);
				translate([-$cRadius, -$cRadius]) square([2* $cRadius, $cRadius]);
			}

			translate([-$cRadius*2, -$cRadius]) square([3* $cRadius, 2*$cRadius]);
		}
	}
}

module maleConnector_filaAxis() {
	difference() {
		maleConnector_disk();
		translate([0, 0, -0.1]) cylinder(d = filamentDiameter + 0.25, h = connectorThickness + 1, $fn = 15);
	}
}

module maleConnector_clickAxis() {
	difference() {
		maleConnector_disk();
		translate([0, 0, -0.1]) cylinder(d = clickAxisDiameter + clearing, h = 1000, $fn = 15);
		translate([-clickAxisDiameter/2, 0, -0.1]) cube([clickAxisDiameter, $cRadius + 1, 0.3]);
	}
}

module maleConnector_standingFilaAxis() {
	translate([0, 0, $cRadius])
	rotate([90, 0, 0])
	maleConnector_filaAxis();
}

module maleConnector_standingClickAxis() {
	translate([0, 0, $cRadius])
	rotate([90, 0, 0])
	maleConnector_clickAxis();
}

module MaleConnector() {
	if(axisType == "click") {
		maleConnector_standingClickAxis();
	}
	else {
		maleConnector_standingFilaAxis();
	}
}
