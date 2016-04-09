$mountWallThickness = 1.5;

// boardStuff array consisting of: [[width, height], [p1 X, p1Y], etc...]

//Config value to change the screw hole size so that the printer doesn't make them too small.
screwHoleCompensation = 0.2;

megaPosition = [[0, 70], 0];
raspiPosition = [[85, 56], 180];

boardMountHeight = 6;
boardHeight = 50;

shellOffset = 15;
shellWall = 0.8;

fanSize = [30, 30, 10];
fanPosition = [	[107, 13, 13], 72];

cutoutCubes = [	[[17, 18], [-shellOffset + 2.5, 1, boardMountHeight], 90],
 								[[17, 18], [-shellOffset + 2.5, 3 + 18, boardMountHeight], 90],
								[[14, 12], [-shellOffset + 2.5, 70 + 31.5, boardMountHeight + 1], 90],
								[[21, 15], [-shellOffset + 2.5, 70 - 5, boardMountHeight + 14], 90],
								[[15, 9],  [123, 70 + 32, 30], 90],
								[[15, 9],  [123, 70 + 32 - 13 - 9, 30], 90],
								[[10, 10],	 [25, 135, 30], 0],
								[[10, 10],	 [68, 135, 30], 0]];


lidMountPositions = [	[[0, - 12], 90], [[80, -12], 90],
											[[0, 135.5], -90], [[105, 135.5], -90]];

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
		circle (d = 3 + screwHoleCompensation*2 + $mountWallThickness *2);

		circle (d = 3 + screwHoleCompensation*2 );
	}
}

module eBoard(boardStuff) {
	if($mode == "MOUNTS") {
		for(i=[1:len(boardStuff)-1]) {
			translate(boardStuff[i]) mountPin();	
		}
	}
	else if($mode == "CUTOUT_MOUNTS") {
		for(i=[1:len(boardStuff)-1]) {
			translate(boardStuff[i]) circle(d = 3 + screwHoleCompensation*2 );
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

		#translate(fanPosition[0]) rotate([0, 0, fanPosition[1]]) for(i=[0:fanSize[2]]) translate([fanSize[0] / fanSize[2] * i, 0, 0]) cube([fanSize[0] / fanSize[2] /2, 5, fanSize[1]]);
	}
}

module cutCubes() {
	difference() {
		children();

		#for(i=[0: len(cutoutCubes) - 1])
			translate(cutoutCubes[i][1])
			rotate([0, 0, cutoutCubes[i][2]])
			cube([cutoutCubes[i][0][0], 5, cutoutCubes[i][0][1]]);
	}
}

module lidMount() {
	$fs = 0.5;
	translate([0, 0, -7])
	difference() {
		union() {
			cylinder(d = 3 + $mountWallThickness*2, h = 7);
			translate([-1.5 - $mountWallThickness, -1.5 - $mountWallThickness, 0]) cube([1.5 + $mountWallThickness, 3 + $mountWallThickness * 2, 7]);
		}
		cylinder(d = 3, h = 10);

		translate([-1.5 - $mountWallThickness, -5, 0]) rotate([0, 45, 0]) cube([10, 10, 10]);
	}
}

module lidMounts() {
	translate([0, 0, caseHeight - shellWall])
	for(i=[0:len(lidMountPositions) -1]) translate(lidMountPositions[i][0]) rotate([0, 0, lidMountPositions[i][1]]) lidMount();
}

module lid() {
		linear_extrude(height = shellWall, convexity = 2) difference() {
			shell2D(r = shellOffset);
			for(i=[0:len(lidMountPositions) - 1]) translate(lidMountPositions[i][0]) circle(d = 3, $fn = 10);
		}
}

module baseCase() {
	difference() {
		union() {
			basePlatform();
			shell(caseHeight);

			linear_extrude(height = boardMountHeight) boards($mode = "MOUNTS", $fs = 0.5);
		}
		linear_extrude(height = boardMountHeight) boards($mode = "CUTOUT_MOUNTS", $fs = 0.5);
	}
}

module baseCaseRefined() {
	fanVentilation()
	cutCubes()

	baseCase();

	lidMounts();
}

baseCaseRefined();
