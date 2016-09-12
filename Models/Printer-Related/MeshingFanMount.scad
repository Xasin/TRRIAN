

$fs = 0.8; 
$fa = 10;

screwRadius = 3.4 /2;
wallThickness = 1.5;

connectorWidth 	= 7;
connectorLength 	= 10;
connectorThickness = 1;

portPlay 		= 0.3;
portThickness 	= 10;

module negatives() color("red") {
	translate([-100, 0, screwRadius + wallThickness]) rotate([0, 90, 0]) cylinder(r = screwRadius, h = 200);
}

module basePlate() {
	translate([-connectorLength/2, -connectorWidth/2, -connectorThickness]) 
		cube([connectorLength, connectorWidth, connectorThickness + 0.001]);
}

module connectorPin() {
	translate([0, -connectorWidth/2, 0]) {
		cube([portThickness, connectorWidth, wallThickness + screwRadius]);
		
		translate([0, connectorWidth/2, wallThickness + screwRadius]) 
			rotate([0, 90, 0]) 
			cylinder(r = connectorWidth/2, h = portThickness);
	}
}

module connectorArray(l = connectorLength) translate([-l/2, 0, 0]) {
	for(i = [0:2*(portThickness + portPlay):l - portThickness]) translate([i, 0, 0]) connectorPin();
}

module base() {
	basePlate();
	connectorArray();
}

module conA() difference() {
	base();
	negatives();
}

conA();