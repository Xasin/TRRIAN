include <Values.scad>

use <FemaleConnector.scad>
use <MaleConnector.scad>

module MFConnectorSetup() {
  additionalHeight = chainLinkLength - (connectorRadius*2 + connectorThickness);

  FemaleConnector();
  translate([-connectorRadius, -connectorThickness - clearing, FemaleConnectorHeight() - 0.01]) cube([connectorRadius*2, connectorThickness, additionalHeight + 0.02]);
  translate([0, -clearing, FemaleConnectorHeight() + additionalHeight]) MaleConnector();
}

module FilaAxisCutout() {
	if(axisType == "filament") {
		for(i = [90, 270]) rotate([0, 0, i]) {
			translate([0, 0, wallThickness + filamentDiameter/2]) rotate([90, 0, 0]) cylinder(d = filamentDiameter + 0.2, h = 1000, $fn = 15);
		}
	}
}

module Connectors(r) {
  r = r + connectorThickness;
  rotate([0, 90, 90]) translate([-connectorRadius, -r, 0]) MFConnectorSetup();
  mirror([1, 0, 0]) rotate([0, 90, 90]) translate([-connectorRadius, -r, 0]) MFConnectorSetup();
}
