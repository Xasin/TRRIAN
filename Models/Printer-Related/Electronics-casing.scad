$mountWallThickness = 1;

// boardStuff array consisting of: [[width, height], [p1 X, p1Y], etc...]


megaBoard = [ [101.6, 53.34],
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

module eBoard(boardStuff, mode = "MOUNTS") {
	if(mode == "MOUNTS") {
		for(i=[1:len(boardStuff)-1]) {
			translate(boardStuff[i]) mountPin();
		}
	}
	else if(mode == "OUTLINE") {
		square(boardStuff[0]);
	}
}

eBoard(raspiBoard, "OUTLINE");
