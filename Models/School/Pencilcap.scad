
$fs = 1;
$fa = 5;

pencilSize = 4.9*2;
pencilSpacing = pencilSize + 0.6;
numPencils = 6;
capHeight = 25;

wallThickness = 1;

module pencil_spacing() {
	cylinder(d = pencilSize + 0.1, h = capHeight);
}

module pencil_spacing_array() {
	for(i=[0 : numPencils - 1]) translate([pencilSpacing*i, 0, 0]) pencil_spacing();
}

module pencil_hull() {
	hull() {
		cylinder(d = pencilSize + 0.1 + wallThickness * 2, h = capHeight + wallThickness);
		translate([pencilSpacing * (numPencils - 1), 0, 0]) 		cylinder(d = pencilSize + 0.2 + wallThickness * 2, h = capHeight + wallThickness);
	}
}

difference() {
	pencil_hull();
	translate([0, 0, -0.001]) pencil_spacing_array();
}