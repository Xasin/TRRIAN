use <Connector.scad>

include <Values.scad>


FemaleConnectorHeight = connectorRadius + filamentDiameter/2 + connectorThickness + filamentHoleWallThickness;

module chainPiece() {

	Connectors(chainLinkWidth/2);

	if(gapSize != 0) {
		translate([-chainLinkWidth/2 - connectorThickness,
			0,
		connectorRadius*2 - cablewallThickness])
		cube([chainLinkWidth + 2*connectorThickness,
			FemaleConnectorHeight,
			cablewallThickness]);
  	}
  
	translate([-chainLinkWidth/2, 0, 0]) cube([chainLinkWidth/2 - gapSize/2, FemaleConnectorHeight, cablewallThickness]);
	translate([gapSize/2, 0, 0]) cube([chainLinkWidth/2 - gapSize/2, FemaleConnectorHeight, cablewallThickness]);
}

chainPiece();
