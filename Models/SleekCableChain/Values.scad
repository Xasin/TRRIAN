function aPoint(a) = [-sin(dToR(a)), cos(dToR(a))];
function dToR(a) = a * 0.017453;


$fs = 1;
$fa = 5;

// === BASIC CONFIG VALUES - Use for most settings ===
  // Maximum angle that the connector will be able to tilt left
  $angle1 = 180 / 4;
  // Minimum angle that the connector will be able to tilt right
  $angle2 = 0;
  // The length that one single piece will extend the cable chain by - set to 0 for minimal
  ChainLinkLength = 15;
  // Radius of the connector pieces -- affects height of the piece!
  connectorRadius = 4;
  // Width of a chain link piece (inside)
  chainLinkWidth = 8;
  // Size of the gap to insert wires through. Put in 0 for a opened-inwards piece
  gapSize = 0;

// Thickness of the walls of the part - can also be specified separately for the connectors themselves.
wallThickness = 1.2;
// Thickness of the walls to hold the cable. They don't need to be that sturdy
cablewallThickness = 1;

// === CONNECTOR-RELATED CONFIG VALUES ===
  // Length of the slip-preventing wall on the outside of the female connector, set to 0 to disable
  antislipLength = 1.5;
  // Diameter of the click-axis (for click-together type chains)
  clickAxisDiameter = 3;
  // Height of the click-axis pin
  clickAxisHeight = 0.75;
  // Diameter of the filament (for Fila-Axis type chains)
  filamentDiameter = 1.75;
  // Separate config value to tweak the connector thickness.
  connectorThickness = wallThickness;
  // Height of the small wall next to the filament hole
  filamentHoleWallThickness = 1.2;

// Clearing for some of the parts (like between female and male connector)
clearing = 0.2;
// Computational value
$cRadius = connectorRadius;
// Computational value
chainLinkLength = (ChainLinkLength == 0) ? connectorRadius * 2 + connectorThickness + 0.1 : ChainLinkLength;
// Computational value
axisType = "filament";
