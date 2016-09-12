
// Total width of the chain pieces
chainWidth = 15;
// Length of one of the chain pieces
chainLength = 20;

// Thickness of the base of the chain
baseThickness = 1.2;
// Diameter of the wire used for the chain
wireDiameter = 1;
// Number of wires used 
wireAmount = 2;

// Spacing of the wire from the outer edge of the chain
wireSpacing = 1.3;


module wires() {
	$fn = 10;
	for(i = [0:wireAmount - 1]) {
		translate([wireSpacing + i * (chainWidth - wireSpacing *2), -0.5, 0]) rotate([-90, 0, 0]) cylinder(d = wireDiameter, h = chainLength + 1);
	}
}

module base() {
	difference() {
		cube([chainWidth, chainLength, baseThickness]);
		wires();
	}
}

base();