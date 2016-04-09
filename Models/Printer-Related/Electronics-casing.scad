$mountWallThickness = 1;

// boardStuff array consisting of: [[width, height], [p1 X, p1Y], etc...]

megaPosition = [[0, 65], 0];
raspiPosition = [[85, 56], 180];

boardMountHeight = 6;
boardHeight = 50;

shellOffset = 10;
shellWall = 1;

fanSize = [30, 30, 10];
fanPosition = [	[102, 13, 13], 72];

caseHeight = boardMountHeight + boardHeight;

baseHeight = shellWall;

megaBoard = [ [105.6, 53.34],
							[13.97, 2.54],
							[96.52, 2.54],
							[90.17, 50.8],
							[15.24, 50.8]];

raspiBoard = [	[85, 56],
								[3.5, 3.5],
								[3.5, 52.5],
								[61.5, 52.5],
								[61.5, 3.5]];

module mountPin() {
	difference() {
		circle (d = 3 + $mountWallThickness *2);

		circle (d = 3);
	}
}

module eBoard(boardStuff) {
	if($mode == "MOUNTS") {
		for(i=[1:len(boardStuff)-1]) {
			translate(boardStuff[i]) mountPin();
		}
	}
	else if($mode == "OUTLINE") {
		square(boardStuff[0]);
	}
}

module boards() {
	translate(megaPosition[0]) rotate([0, 0, megaPosition[1]]) eBoard(megaBoard, $mode);
	translate(raspiPosition[0]) rotate([0, 0, raspiPosition[1]]) eBoard(raspiBoard, $mode);
}

module shell2D(r = 15) {
	offset(r = r) hull() boards($mode = "OUTLINE");
}

module basePlatform() {
	linear_extrude(height = baseHeight) shell2D(r = shellOffset + shellWall);
}

module shell(height = 10) {
	linear_extrude(height = height, convexity = 2) difference() {
		shell2D(r = shellOffset + shellWall);
		shell2D(r = shellOffset);
	}
}

module fanVentilation() {
	difference() {
		children();

		translate(fanPosition[0]) rotate([0, 0, fanPosition[1]]) for(i=[0:fanSize[2]]) translate([fanSize[0] / fanSize[2] * i, 0, 0]) cube([fanSize[0] / fanSize[2] /2, 5, fanSize[1]]);
	}
}

module baseCase() {
	basePlatform();
	shell(caseHeight);

	linear_extrude(height = boardMountHeight) boards($mode = "MOUNTS", $fs = 0.5);
}

module baseCaseRefined() {
	fanVentilation()

	baseCase();
}

baseCaseRefined();
