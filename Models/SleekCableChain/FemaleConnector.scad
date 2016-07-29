include <Values.scad>

function FemaleConnectorHeight_click() = $cRadius + clickAxisDiameter/2 + connectorThickness;
function FemaleConnectorHeight_filament() = $cRadius + filamentDiameter/2 + connectorThickness + filamentHoleWallThickness;

function FemaleConnectorHeight() = (axisType == "click") ? FemaleConnectorHeight_click($cRadius, connectorThickness) : FemaleConnectorHeight_filament($cRadius, connectorThickness);

module FemaleConnector_disk() {
  translate([-$cRadius, -$cRadius, 0]) cube([2*$cRadius, 2*$cRadius, connectorThickness]);
  translate([-$cRadius, $cRadius, 0]) cube([2*$cRadius, connectorThickness, connectorThickness*2 + clearing + ((antislipLength != 0) ? clearing : 0)]);

  if(antislipLength != 0) {
    translate([-$cRadius, connectorRadius - antislipLength, connectorThickness*2 + clearing*2]) cube([2*$cRadius, antislipLength + connectorThickness, wallThickness]);
  }
}

module FemaleConnector_filaAxis() {
  difference() {
    FemaleConnector_disk();
    translate([0, 0, -0.1]) cylinder(d = filamentDiameter + 0.12, h = 1000, $fn = 15);
  }
}

module FemaleConnector_clickAxis() {
  FemaleConnector_disk();
  translate([0, 0, connectorThickness]) cylinder(d = clickAxisDiameter, h = clickAxisHeight, $fn = 15);
}

module FemaleConnector_standingClickAxis() {
  intersection() {
    translate([0, connectorThickness, clickAxisDiameter/2])
    rotate([90, 0, 0])
    FemaleConnector_clickAxis($cRadius);

    translate([-$cRadius, - (connectorThickness*2 + clearing*2), 0]) cube([2*$cRadius, connectorThickness*3 + clearing*2, FemaleConnectorHeight_click($cRadius)]);
  }
}

module FemaleConnector_standingFilamentAxis() {
  intersection() {
    translate([0, connectorThickness, filamentDiameter/2 + filamentHoleWallThickness])
    rotate([90, 0, 0])
    FemaleConnector_filaAxis($cRadius);

    translate([-connectorRadius, - (connectorThickness*2 + clearing*2), 0]) cube([2*$cRadius, connectorThickness * 3 + clearing*2, FemaleConnectorHeight_filament($cRadius)]);
  }
}

module FemaleConnector() {
  if(axisType == "click") {
    FemaleConnector_standingClickAxis($cRadius);
  }
  else {
    FemaleConnector_standingFilamentAxis($cRadius);
  }
}
